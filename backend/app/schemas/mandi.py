from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import date
from decimal import Decimal


class MandiPriceSchema(BaseModel):
    """Schema for mandi price."""

    id: str
    crop_name: str
    crop_name_local: Optional[str] = None
    price_per_quintal: Decimal
    mandi_name: str
    mandi_id: str
    price_date: date
    min_price: Optional[Decimal] = None
    max_price: Optional[Decimal] = None
    unit: str = "quintal"
    price_change_percent: Optional[float] = None

    class Config:
        from_attributes = True


class MandiPriceListSchema(BaseModel):
    """Schema for mandi price list response."""

    items: List[MandiPriceSchema]
    total: int
    page: int
    limit: int
    cached: bool = False
    cache_age_seconds: Optional[int] = None

    class Config:
        examples = [
            {
                "items": [
                    {
                        "id": "123e4567-e89b-12d3-a456-426614174000",
                        "crop_name": "Wheat",
                        "crop_name_local": "गेहूं",
                        "price_per_quintal": 2500.00,
                        "mandi_name": "Indore Mandi",
                        "mandi_id": "123e4567-e89b-12d3-a456-426614174001",
                        "price_date": "2026-03-22",
                        "min_price": 2400.00,
                        "max_price": 2600.00,
                        "unit": "quintal",
                        "price_change_percent": 1.5,
                    }
                ],
                "total": 100,
                "page": 1,
                "limit": 20,
                "cached": True,
                "cache_age_seconds": 145,
            }
        ]


class MandiSearchSchema(BaseModel):
    """Schema for mandi search."""

    query: str = Field(..., min_length=1, max_length=255)
    region_id: Optional[str] = None

    class Config:
        examples = [{"query": "wheat", "region_id": None}]
