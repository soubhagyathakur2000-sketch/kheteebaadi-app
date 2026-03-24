from pydantic import BaseModel, Field, field_validator
from typing import Optional, List
from datetime import datetime
from decimal import Decimal


class OrderItemCreateSchema(BaseModel):
    """Schema for creating order item."""

    crop_name: str = Field(..., max_length=255)
    quantity: Decimal = Field(..., gt=0)
    unit: str = Field(..., max_length=50)
    price_per_unit: Decimal = Field(..., gt=0)

    class Config:
        examples = [
            {
                "crop_name": "Wheat",
                "quantity": 50.0,
                "unit": "quintal",
                "price_per_unit": 2500.0,
            }
        ]


class OrderCreateSchema(BaseModel):
    """Schema for creating order."""

    items: List[OrderItemCreateSchema] = Field(..., min_items=1)
    delivery_address: str = Field(..., min_length=10, max_length=1000)
    notes: Optional[str] = Field(None, max_length=1000)

    @field_validator("items")
    @classmethod
    def validate_items(cls, v: List[OrderItemCreateSchema]) -> List[OrderItemCreateSchema]:
        """Validate items list."""
        if len(v) > 50:
            raise ValueError("Cannot have more than 50 items in an order")
        return v

    class Config:
        examples = [
            {
                "items": [
                    {
                        "crop_name": "Wheat",
                        "quantity": 50.0,
                        "unit": "quintal",
                        "price_per_unit": 2500.0,
                    }
                ],
                "delivery_address": "123 Main Street, Village, District, State 123456",
                "notes": "Please deliver in the morning",
            }
        ]


class OrderItemResponseSchema(BaseModel):
    """Schema for order item response."""

    id: str
    crop_name: str
    quantity: Decimal
    unit: str
    price_per_unit: Decimal
    subtotal: Decimal

    class Config:
        from_attributes = True


class OrderResponseSchema(BaseModel):
    """Schema for order response."""

    id: str
    order_number: str
    status: str
    items: List[OrderItemResponseSchema]
    total_amount: Decimal
    delivery_address: str
    notes: Optional[str] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class OrderListSchema(BaseModel):
    """Schema for order list response."""

    items: List[OrderResponseSchema]
    total: int
    page: int
    limit: int

    class Config:
        examples = [
            {
                "items": [
                    {
                        "id": "123e4567-e89b-12d3-a456-426614174000",
                        "order_number": "ORD-20260322-001",
                        "status": "pending",
                        "items": [
                            {
                                "id": "123e4567-e89b-12d3-a456-426614174001",
                                "crop_name": "Wheat",
                                "quantity": 50.0,
                                "unit": "quintal",
                                "price_per_unit": 2500.0,
                                "subtotal": 125000.0,
                            }
                        ],
                        "total_amount": 125000.0,
                        "delivery_address": "123 Main Street",
                        "notes": None,
                        "created_at": "2026-03-22T10:30:00Z",
                        "updated_at": "2026-03-22T10:30:00Z",
                    }
                ],
                "total": 10,
                "page": 1,
                "limit": 20,
            }
        ]


class OrderStatusUpdateSchema(BaseModel):
    """Schema for order status update."""

    status: str = Field(..., pattern="^(pending|confirmed|processing|shipped|delivered|cancelled)$")

    class Config:
        examples = [{"status": "confirmed"}]
