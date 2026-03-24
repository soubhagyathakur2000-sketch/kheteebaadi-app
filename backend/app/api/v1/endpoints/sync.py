from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.redis import get_redis, RedisClient
from app.core.security import get_current_user
from app.schemas.sync import SyncBatchRequestSchema, SyncBatchResponseSchema
from app.services.sync_service import SyncService

router = APIRouter()
sync_service = SyncService()


@router.post("/batch", response_model=SyncBatchResponseSchema, status_code=200)
async def sync_batch(
    batch_request: SyncBatchRequestSchema,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
    redis_client: RedisClient = Depends(get_redis),
):
    """
    Process batch of offline mutations (sync endpoint).

    This endpoint handles offline-first synchronization. Each item in the batch
    is processed with idempotency checking to ensure no duplicates even with
    network retries.

    - **items**: List of sync items (max 50)
      - **entity_type**: Type of entity (order, profile_update, etc.)
      - **entity_id**: Local ID on client
      - **action**: create, update, or delete
      - **payload**: Entity data
      - **idempotency_key**: Unique key for this operation
    """
    return await sync_service.process_batch(
        db=db,
        redis_client=redis_client,
        user_id=current_user.get("user_id"),
        items=batch_request.items,
    )
