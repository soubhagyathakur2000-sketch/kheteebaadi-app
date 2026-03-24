import pytest
from unittest.mock import AsyncMock, patch
import uuid

from app.core.security import create_access_token


@pytest.mark.asyncio
class TestSyncBatchEndpoint:
    """Test POST /sync/batch endpoint."""

    async def test_sync_batch_five_items_all_succeed(self, test_app, sample_user, test_db, test_redis):
        """Test sync batch with 5 items all succeeding."""
        access_token = create_access_token({"sub": str(sample_user.id)})
        headers = {"Authorization": f"Bearer {access_token}"}

        batch_request = {
            "items": [
                {
                    "entity_type": "order",
                    "entity_id": f"local_order_{i}",
                    "action": "create",
                    "payload": {
                        "items": [
                            {
                                "crop_name": f"Crop_{i}",
                                "quantity": 50.0,
                                "unit": "quintal",
                                "price_per_unit": 2500.0 + (i * 100),
                            }
                        ],
                        "delivery_address": f"{i}00 Main Street, Test Village",
                        "notes": f"Sync order {i}",
                    },
                    "idempotency_key": f"test_order_{i}_{uuid.uuid4()}",
                }
                for i in range(5)
            ]
        }

        response = await test_app.post(
            "/api/v1/sync/batch",
            json=batch_request,
            headers=headers,
        )

        assert response.status_code == 200
        data = response.json()
        assert "results" in data
        assert len(data["results"]) == 5
        assert "processed" in data
        assert "failed" in data
        assert "duplicates" in data

    async def test_sync_batch_duplicate_idempotency_key_processed_once(self, test_app, sample_user, test_redis):
        """Test batch with duplicate idempotency key processes only once."""
        access_token = create_access_token({"sub": str(sample_user.id)})
        headers = {"Authorization": f"Bearer {access_token}"}

        idempotency_key = f"test_dup_{uuid.uuid4()}"

        batch_request = {
            "items": [
                {
                    "entity_type": "order",
                    "entity_id": "local_order_1",
                    "action": "create",
                    "payload": {
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
                    "idempotency_key": idempotency_key,
                },
                {
                    "entity_type": "order",
                    "entity_id": "local_order_2",
                    "action": "create",
                    "payload": {
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
                    "idempotency_key": idempotency_key,  # Same key
                },
            ]
        }

        response = await test_app.post(
            "/api/v1/sync/batch",
            json=batch_request,
            headers=headers,
        )

        assert response.status_code == 200
        data = response.json()
        # Should have one success and one duplicate
        assert data["processed"] + data["duplicates"] == 2
        assert data["duplicates"] == 1

    async def test_sync_batch_requires_authentication(self, test_app):
        """Test sync batch endpoint requires authentication."""
        batch_request = {
            "items": [
                {
                    "entity_type": "order",
                    "entity_id": "local_order_1",
                    "action": "create",
                    "payload": {
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
                    "idempotency_key": "key_1",
                }
            ]
        }

        response = await test_app.post(
            "/api/v1/sync/batch",
            json=batch_request,
        )

        assert response.status_code in [401, 403]

    async def test_sync_batch_mixed_success_failure(self, test_app, sample_user, test_redis):
        """Test batch with mixed success and failure items."""
        access_token = create_access_token({"sub": str(sample_user.id)})
        headers = {"Authorization": f"Bearer {access_token}"}

        batch_request = {
            "items": [
                {
                    "entity_type": "order",  # Valid
                    "entity_id": "local_order_1",
                    "action": "create",
                    "payload": {
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
                    "idempotency_key": f"valid_{uuid.uuid4()}",
                },
                {
                    "entity_type": "invalid_type",  # Invalid
                    "entity_id": "local_order_2",
                    "action": "create",
                    "payload": {"data": "test"},
                    "idempotency_key": f"invalid_{uuid.uuid4()}",
                },
                {
                    "entity_type": "order",  # Valid
                    "entity_id": "local_order_3",
                    "action": "create",
                    "payload": {
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
                    "idempotency_key": f"valid2_{uuid.uuid4()}",
                },
            ]
        }

        response = await test_app.post(
            "/api/v1/sync/batch",
            json=batch_request,
            headers=headers,
        )

        assert response.status_code == 200
        data = response.json()
        # Should have both successes and failures
        assert data["processed"] + data["failed"] > 0
        total_results = data["processed"] + data["failed"] + data["duplicates"]
        assert total_results == 3

    async def test_sync_batch_empty_items_rejected(self, test_app, sample_user):
        """Test batch with empty items list is rejected."""
        access_token = create_access_token({"sub": str(sample_user.id)})
        headers = {"Authorization": f"Bearer {access_token}"}

        batch_request = {"items": []}

        response = await test_app.post(
            "/api/v1/sync/batch",
            json=batch_request,
            headers=headers,
        )

        assert response.status_code in [400, 422]

    async def test_sync_batch_exceeds_max_size(self, test_app, sample_user):
        """Test batch exceeding 50 items is rejected."""
        access_token = create_access_token({"sub": str(sample_user.id)})
        headers = {"Authorization": f"Bearer {access_token}"}

        items = [
            {
                "entity_type": "order",
                "entity_id": f"local_order_{i}",
                "action": "create",
                "payload": {
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
                "idempotency_key": f"key_{i}",
            }
            for i in range(51)
        ]

        batch_request = {"items": items}

        response = await test_app.post(
            "/api/v1/sync/batch",
            json=batch_request,
            headers=headers,
        )

        assert response.status_code in [400, 422]

    async def test_sync_batch_exactly_fifty_items_succeeds(self, test_app, sample_user, test_redis):
        """Test batch with exactly 50 items (maximum allowed) succeeds."""
        access_token = create_access_token({"sub": str(sample_user.id)})
        headers = {"Authorization": f"Bearer {access_token}"}

        items = [
            {
                "entity_type": "order",
                "entity_id": f"local_order_{i}",
                "action": "create",
                "payload": {
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
                "idempotency_key": f"key_{i}_{uuid.uuid4()}",
            }
            for i in range(50)
        ]

        batch_request = {"items": items}

        response = await test_app.post(
            "/api/v1/sync/batch",
            json=batch_request,
            headers=headers,
        )

        assert response.status_code == 200
        data = response.json()
        assert len(data["results"]) == 50


@pytest.mark.asyncio
class TestSyncBatchIdempotency:
    """Test idempotency in sync batch endpoint."""

    async def test_resend_same_batch_no_duplicates(self, test_app, sample_user, test_redis):
        """Test resending same batch doesn't create duplicates."""
        access_token = create_access_token({"sub": str(sample_user.id)})
        headers = {"Authorization": f"Bearer {access_token}"}

        idempotency_key = f"test_batch_{uuid.uuid4()}"

        batch_request = {
            "items": [
                {
                    "entity_type": "order",
                    "entity_id": "local_order_1",
                    "action": "create",
                    "payload": {
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
                    "idempotency_key": idempotency_key,
                }
            ]
        }

        # First request
        response1 = await test_app.post(
            "/api/v1/sync/batch",
            json=batch_request,
            headers=headers,
        )
        assert response1.status_code == 200
        data1 = response1.json()

        # Second request with same batch
        response2 = await test_app.post(
            "/api/v1/sync/batch",
            json=batch_request,
            headers=headers,
        )
        assert response2.status_code == 200
        data2 = response2.json()

        # Second should recognize duplicate
        assert data2["duplicates"] >= 1
