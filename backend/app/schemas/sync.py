from pydantic import BaseModel, Field, field_validator
from typing import Optional, List, Dict, Any


class SyncItemSchema(BaseModel):
    """Schema for a single sync item."""

    entity_type: str = Field(..., max_length=100)
    entity_id: str = Field(..., max_length=255)
    action: str = Field(..., pattern="^(create|update|delete)$")
    payload: Dict[str, Any] = Field(...)
    idempotency_key: str = Field(..., max_length=255)

    class Config:
        examples = [
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
                    "notes": None,
                },
                "idempotency_key": "user123_order_001_1648000000",
            }
        ]


class SyncBatchRequestSchema(BaseModel):
    """Schema for batch sync request."""

    items: List[SyncItemSchema] = Field(..., min_items=1)

    @field_validator("items")
    @classmethod
    def validate_batch_size(cls, v: List[SyncItemSchema]) -> List[SyncItemSchema]:
        """Validate batch size does not exceed maximum."""
        if len(v) > 50:
            raise ValueError("Batch cannot contain more than 50 items")
        return v

    class Config:
        examples = [
            {
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
                            "notes": None,
                        },
                        "idempotency_key": "user123_order_001_1648000000",
                    }
                ]
            }
        ]


class SyncItemResultSchema(BaseModel):
    """Schema for sync item result."""

    idempotency_key: str
    status: str = Field(..., pattern="^(success|failed|duplicate)$")
    entity_id: Optional[str] = None
    error: Optional[str] = None

    class Config:
        examples = [
            {
                "idempotency_key": "user123_order_001_1648000000",
                "status": "success",
                "entity_id": "123e4567-e89b-12d3-a456-426614174000",
                "error": None,
            },
            {
                "idempotency_key": "user123_order_002_1648000001",
                "status": "duplicate",
                "entity_id": None,
                "error": "Sync item already processed",
            },
            {
                "idempotency_key": "user123_order_003_1648000002",
                "status": "failed",
                "entity_id": None,
                "error": "Invalid delivery address",
            },
        ]


class SyncBatchResponseSchema(BaseModel):
    """Schema for batch sync response."""

    results: List[SyncItemResultSchema]
    processed: int
    failed: int
    duplicates: int

    class Config:
        examples = [
            {
                "results": [
                    {
                        "idempotency_key": "user123_order_001_1648000000",
                        "status": "success",
                        "entity_id": "123e4567-e89b-12d3-a456-426614174000",
                        "error": None,
                    }
                ],
                "processed": 1,
                "failed": 0,
                "duplicates": 0,
            }
        ]
