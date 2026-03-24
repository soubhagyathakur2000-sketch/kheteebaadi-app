from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from datetime import datetime, timezone
import uuid
import structlog

from app.core.redis import RedisClient
from app.core.config import settings
from app.core.exceptions import ValidationException
from app.models import SyncLog, Order, OrderItem
from app.models.sync_log import SyncStatus
from app.schemas.sync import SyncItemSchema, SyncItemResultSchema, SyncBatchResponseSchema
from app.services.order_service import OrderService

logger = structlog.get_logger(__name__)
order_service = OrderService()


class SyncService:
    """Service for sync operations."""

    async def process_batch(
        self,
        db: AsyncSession,
        redis_client: RedisClient,
        user_id: str,
        items: list[SyncItemSchema],
    ) -> SyncBatchResponseSchema:
        """
        Process batch of offline mutations with idempotency checking.

        All items are processed within a database transaction.
        """
        results = []
        processed_count = 0
        failed_count = 0
        duplicate_count = 0

        try:
            for item in items:
                result = await self._process_item(
                    db=db,
                    redis_client=redis_client,
                    user_id=user_id,
                    item=item,
                )
                results.append(result)

                if result.status == "success":
                    processed_count += 1
                elif result.status == "failed":
                    failed_count += 1
                elif result.status == "duplicate":
                    duplicate_count += 1

            await db.commit()
            logger.info(
                "Sync batch processed",
                user_id=user_id,
                total=len(items),
                processed=processed_count,
                failed=failed_count,
                duplicates=duplicate_count,
            )
        except Exception as e:
            await db.rollback()
            logger.error("Sync batch processing failed", error=str(e), user_id=user_id)
            raise

        return SyncBatchResponseSchema(
            results=results,
            processed=processed_count,
            failed=failed_count,
            duplicates=duplicate_count,
        )

    async def _process_item(
        self,
        db: AsyncSession,
        redis_client: RedisClient,
        user_id: str,
        item: SyncItemSchema,
    ) -> SyncItemResultSchema:
        """
        Process a single sync item.

        Returns SyncItemResultSchema with status (success/failed/duplicate) and any error.
        """
        try:
            # Check for duplicate using idempotency key
            is_duplicate = await self._check_idempotency(
                redis=redis_client,
                user_id=user_id,
                key=item.idempotency_key,
            )

            if is_duplicate:
                logger.info(
                    "Duplicate sync item",
                    user_id=user_id,
                    idempotency_key=item.idempotency_key,
                )
                return SyncItemResultSchema(
                    idempotency_key=item.idempotency_key,
                    status="duplicate",
                    error="Sync item already processed",
                )

            # Process based on entity type
            entity_id = None

            if item.entity_type == "order":
                if item.action == "create":
                    order_items = [
                        {
                            "crop_name": i["crop_name"],
                            "quantity": float(i["quantity"]),
                            "unit": i["unit"],
                            "price_per_unit": float(i["price_per_unit"]),
                        }
                        for i in item.payload.get("items", [])
                    ]

                    from app.schemas.order import OrderItemCreateSchema, OrderCreateSchema
                    from decimal import Decimal

                    validated_items = [
                        OrderItemCreateSchema(
                            crop_name=i["crop_name"],
                            quantity=Decimal(str(i["quantity"])),
                            unit=i["unit"],
                            price_per_unit=Decimal(str(i["price_per_unit"])),
                        )
                        for i in order_items
                    ]

                    order = await order_service.create_order(
                        db=db,
                        user_id=user_id,
                        items=validated_items,
                        delivery_address=item.payload.get("delivery_address", ""),
                        notes=item.payload.get("notes"),
                    )
                    entity_id = order.id

            elif item.entity_type == "profile_update":
                if item.action == "update":
                    # Import here to avoid circular imports
                    from app.models import User
                    from sqlalchemy import update

                    stmt = update(User).where(User.id == uuid.UUID(user_id))

                    if "name" in item.payload:
                        stmt = stmt.values(name=item.payload["name"])
                    if "language_pref" in item.payload:
                        stmt = stmt.values(language_pref=item.payload["language_pref"])

                    await db.execute(stmt)
                    entity_id = user_id

            else:
                raise ValidationException(f"Unknown entity type: {item.entity_type}")

            # Record in sync log
            sync_log = SyncLog(
                id=uuid.uuid4(),
                user_id=uuid.UUID(user_id),
                idempotency_key=item.idempotency_key,
                entity_type=item.entity_type,
                entity_id=entity_id or item.entity_id,
                action=item.action,
                payload=item.payload,
                status=SyncStatus.PROCESSED,
                processed_at=datetime.now(timezone.utc),
            )
            db.add(sync_log)

            # Store idempotency key in Redis
            await self._record_idempotency(
                redis=redis_client,
                user_id=user_id,
                key=item.idempotency_key,
                ttl=settings.SYNC_IDEMPOTENCY_TTL_HOURS * 3600,
            )

            logger.info(
                "Sync item processed",
                user_id=user_id,
                entity_type=item.entity_type,
                action=item.action,
                idempotency_key=item.idempotency_key,
            )

            return SyncItemResultSchema(
                idempotency_key=item.idempotency_key,
                status="success",
                entity_id=entity_id,
            )

        except ValidationException as e:
            logger.warning(
                "Sync item validation failed",
                user_id=user_id,
                idempotency_key=item.idempotency_key,
                error=str(e),
            )
            return SyncItemResultSchema(
                idempotency_key=item.idempotency_key,
                status="failed",
                error=str(e),
            )
        except Exception as e:
            logger.error(
                "Sync item processing failed",
                user_id=user_id,
                idempotency_key=item.idempotency_key,
                error=str(e),
            )

            # Record failed sync
            sync_log = SyncLog(
                id=uuid.uuid4(),
                user_id=uuid.UUID(user_id),
                idempotency_key=item.idempotency_key,
                entity_type=item.entity_type,
                entity_id=item.entity_id,
                action=item.action,
                payload=item.payload,
                status=SyncStatus.FAILED,
                error_message=str(e),
                processed_at=datetime.now(timezone.utc),
            )
            db.add(sync_log)

            return SyncItemResultSchema(
                idempotency_key=item.idempotency_key,
                status="failed",
                error=str(e),
            )

    async def _check_idempotency(
        self, redis: RedisClient, user_id: str, key: str
    ) -> bool:
        """Check if idempotency key already exists."""
        cache_key = f"processed_sync:{user_id}:{key}"
        return await redis.exists(cache_key)

    async def _record_idempotency(
        self, redis: RedisClient, user_id: str, key: str, ttl: int
    ):
        """Record processed idempotency key in Redis."""
        cache_key = f"processed_sync:{user_id}:{key}"
        await redis.set_cached(cache_key, True, ttl=ttl)
