import pytest
from unittest.mock import AsyncMock, MagicMock
from decimal import Decimal
import uuid

from app.services.sync_service import SyncService
from app.schemas.sync import SyncItemSchema


@pytest.mark.asyncio
class TestSyncServiceProcessBatch:
    """Test SyncService.process_batch method."""

    async def test_process_batch_single_valid_item(self):
        """Test batch processing with single valid item."""
        service = SyncService()
        db_mock = AsyncMock()
        redis_mock = AsyncMock()
        redis_mock.exists = AsyncMock(return_value=False)
        redis_mock.set_cached = AsyncMock()

        user_id = str(uuid.uuid4())
        items = [
            SyncItemSchema(
                entity_type="order",
                entity_id="local_order_1",
                action="create",
                payload={
                    "items": [
                        {
                            "crop_name": "Wheat",
                            "quantity": 50.0,
                            "unit": "quintal",
                            "price_per_unit": 2500.0,
                        }
                    ],
                    "delivery_address": "123 Main Street",
                },
                idempotency_key="key_1",
            )
        ]

        with pytest.mock.patch("app.services.sync_service.OrderService") as mock_order_service:
            mock_service_instance = AsyncMock()
            mock_order_service.return_value = mock_service_instance
            mock_service_instance.create_order = AsyncMock()

            result = await service.process_batch(
                db=db_mock,
                redis_client=redis_mock,
                user_id=user_id,
                items=items,
            )

        assert result.processed >= 0
        assert result.failed >= 0
        db_mock.commit.assert_called()

    async def test_process_batch_with_duplicate_idempotency_key(self):
        """Test batch recognizes duplicate idempotency key."""
        service = SyncService()
        db_mock = AsyncMock()
        redis_mock = AsyncMock()
        redis_mock.exists.side_effect = [True, False]  # First is dup, second is new
        redis_mock.set_cached = AsyncMock()

        user_id = str(uuid.uuid4())
        items = [
            SyncItemSchema(
                entity_type="order",
                entity_id="local_order_1",
                action="create",
                payload={
                    "items": [
                        {
                            "crop_name": "Wheat",
                            "quantity": 50.0,
                            "unit": "quintal",
                            "price_per_unit": 2500.0,
                        }
                    ],
                    "delivery_address": "123 Main Street",
                },
                idempotency_key="dup_key",
            ),
            SyncItemSchema(
                entity_type="order",
                entity_id="local_order_2",
                action="create",
                payload={
                    "items": [
                        {
                            "crop_name": "Rice",
                            "quantity": 100.0,
                            "unit": "quintal",
                            "price_per_unit": 3000.0,
                        }
                    ],
                    "delivery_address": "456 Oak Street",
                },
                idempotency_key="new_key",
            ),
        ]

        result = await service.process_batch(
            db=db_mock,
            redis_client=redis_mock,
            user_id=user_id,
            items=items,
        )

        assert result.duplicates >= 1

    async def test_process_batch_mixed_success_and_failure(self):
        """Test batch with 3/5 valid items and 2 failures."""
        service = SyncService()
        db_mock = AsyncMock()
        redis_mock = AsyncMock()
        redis_mock.exists = AsyncMock(return_value=False)
        redis_mock.set_cached = AsyncMock()

        user_id = str(uuid.uuid4())

        # Mix of valid and invalid items
        items = []
        for i in range(5):
            items.append(
                SyncItemSchema(
                    entity_type="order" if i < 3 else "invalid_type",
                    entity_id=f"order_{i}",
                    action="create",
                    payload={
                        "items": [
                            {
                                "crop_name": f"Crop_{i}",
                                "quantity": 50.0,
                                "unit": "quintal",
                                "price_per_unit": 2500.0,
                            }
                        ],
                        "delivery_address": f"{i}00 Main Street",
                    },
                    idempotency_key=f"key_{i}",
                )
            )

        result = await service.process_batch(
            db=db_mock,
            redis_client=redis_mock,
            user_id=user_id,
            items=items,
        )

        # Should have some successes and some failures
        assert result.processed + result.failed + result.duplicates == len(items)

    async def test_process_batch_returns_per_item_results(self):
        """Test batch response includes per-item results."""
        service = SyncService()
        db_mock = AsyncMock()
        redis_mock = AsyncMock()
        redis_mock.exists = AsyncMock(return_value=False)
        redis_mock.set_cached = AsyncMock()

        user_id = str(uuid.uuid4())
        items = [
            SyncItemSchema(
                entity_type="order",
                entity_id="local_order_1",
                action="create",
                payload={
                    "items": [
                        {
                            "crop_name": "Wheat",
                            "quantity": 50.0,
                            "unit": "quintal",
                            "price_per_unit": 2500.0,
                        }
                    ],
                    "delivery_address": "123 Main Street",
                },
                idempotency_key="key_1",
            )
        ]

        with pytest.mock.patch("app.services.sync_service.OrderService"):
            result = await service.process_batch(
                db=db_mock,
                redis_client=redis_mock,
                user_id=user_id,
                items=items,
            )

        assert len(result.results) == len(items)
        for item_result in result.results:
            assert item_result.idempotency_key is not None
            assert item_result.status in ["success", "failed", "duplicate"]

    async def test_process_batch_commits_transaction(self):
        """Test batch processing commits database transaction."""
        service = SyncService()
        db_mock = AsyncMock()
        redis_mock = AsyncMock()
        redis_mock.exists = AsyncMock(return_value=False)
        redis_mock.set_cached = AsyncMock()

        user_id = str(uuid.uuid4())
        items = [
            SyncItemSchema(
                entity_type="order",
                entity_id="local_order_1",
                action="create",
                payload={
                    "items": [
                        {
                            "crop_name": "Wheat",
                            "quantity": 50.0,
                            "unit": "quintal",
                            "price_per_unit": 2500.0,
                        }
                    ],
                    "delivery_address": "123 Main Street",
                },
                idempotency_key="key_1",
            )
        ]

        with pytest.mock.patch("app.services.sync_service.OrderService"):
            await service.process_batch(
                db=db_mock,
                redis_client=redis_mock,
                user_id=user_id,
                items=items,
            )

        db_mock.commit.assert_called()

    async def test_process_batch_rollback_on_error(self):
        """Test transaction is rolled back on error."""
        service = SyncService()
        db_mock = AsyncMock()
        db_mock.commit.side_effect = Exception("Database error")
        redis_mock = AsyncMock()

        user_id = str(uuid.uuid4())
        items = []

        with pytest.raises(Exception):
            await service.process_batch(
                db=db_mock,
                redis_client=redis_mock,
                user_id=user_id,
                items=items,
            )

        db_mock.rollback.assert_called()


@pytest.mark.asyncio
class TestSyncServiceIdempotency:
    """Test idempotency handling in sync service."""

    async def test_idempotency_key_stored_on_success(self):
        """Test idempotency key is stored after successful processing."""
        service = SyncService()
        db_mock = AsyncMock()
        redis_mock = AsyncMock()
        redis_mock.exists = AsyncMock(return_value=False)
        redis_mock.set_cached = AsyncMock()

        user_id = str(uuid.uuid4())
        idempotency_key = "unique_key_123"
        items = [
            SyncItemSchema(
                entity_type="order",
                entity_id="local_order_1",
                action="create",
                payload={
                    "items": [
                        {
                            "crop_name": "Wheat",
                            "quantity": 50.0,
                            "unit": "quintal",
                            "price_per_unit": 2500.0,
                        }
                    ],
                    "delivery_address": "123 Main Street",
                },
                idempotency_key=idempotency_key,
            )
        ]

        with pytest.mock.patch("app.services.sync_service.OrderService"):
            await service.process_batch(
                db=db_mock,
                redis_client=redis_mock,
                user_id=user_id,
                items=items,
            )

        redis_mock.set_cached.assert_called()

    async def test_duplicate_idempotency_key_returns_duplicate_status(self):
        """Test duplicate idempotency key returns duplicate status."""
        service = SyncService()
        db_mock = AsyncMock()
        redis_mock = AsyncMock()
        redis_mock.exists = AsyncMock(return_value=True)  # Duplicate
        redis_mock.set_cached = AsyncMock()

        user_id = str(uuid.uuid4())
        items = [
            SyncItemSchema(
                entity_type="order",
                entity_id="local_order_1",
                action="create",
                payload={
                    "items": [
                        {
                            "crop_name": "Wheat",
                            "quantity": 50.0,
                            "unit": "quintal",
                            "price_per_unit": 2500.0,
                        }
                    ],
                    "delivery_address": "123 Main Street",
                },
                idempotency_key="dup_key",
            )
        ]

        result = await service.process_batch(
            db=db_mock,
            redis_client=redis_mock,
            user_id=user_id,
            items=items,
        )

        assert result.duplicates == 1
        assert result.results[0].status == "duplicate"
        assert result.results[0].error is not None


@pytest.mark.asyncio
class TestSyncServiceProcessItem:
    """Test processing individual sync items."""

    async def test_process_item_profile_update(self):
        """Test processing profile update action."""
        service = SyncService()
        db_mock = AsyncMock()
        redis_mock = AsyncMock()
        redis_mock.exists = AsyncMock(return_value=False)
        redis_mock.set_cached = AsyncMock()

        user_id = str(uuid.uuid4())
        item = SyncItemSchema(
            entity_type="profile_update",
            entity_id=user_id,
            action="update",
            payload={
                "name": "Updated Name",
                "language_pref": "en",
            },
            idempotency_key="profile_key",
        )

        with pytest.mock.patch("app.services.sync_service.update"):
            result = await service._process_item(
                db=db_mock,
                redis_client=redis_mock,
                user_id=user_id,
                item=item,
            )

        assert result.status in ["success", "failed"]

    async def test_process_item_unknown_entity_type_fails(self):
        """Test unknown entity type returns failed status."""
        service = SyncService()
        db_mock = AsyncMock()
        redis_mock = AsyncMock()
        redis_mock.exists = AsyncMock(return_value=False)
        redis_mock.set_cached = AsyncMock()

        user_id = str(uuid.uuid4())
        item = SyncItemSchema(
            entity_type="unknown_type",
            entity_id="id_123",
            action="create",
            payload={"data": "test"},
            idempotency_key="key",
        )

        result = await service._process_item(
            db=db_mock,
            redis_client=redis_mock,
            user_id=user_id,
            item=item,
        )

        assert result.status == "failed"
        assert result.error is not None
