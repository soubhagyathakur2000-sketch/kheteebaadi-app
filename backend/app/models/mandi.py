from sqlalchemy import Column, String, Float, Boolean, DateTime, Date, ForeignKey, Index, Numeric
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from datetime import datetime, timezone
import uuid

from app.core.database import Base


class Mandi(Base):
    """Mandi (market) model."""

    __tablename__ = "mandis"

    id = Column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
        nullable=False,
    )
    name = Column(String(255), nullable=False)
    name_local = Column(String(255), nullable=True)
    district = Column(String(255), nullable=False)
    state = Column(String(255), nullable=False)
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    # Relationships
    prices = relationship("MandiPrice", back_populates="mandi", cascade="all, delete-orphan")

    # Indexes
    __table_args__ = (
        Index("idx_mandi_district", "district"),
        Index("idx_mandi_state", "state"),
        Index("idx_mandi_coords", "latitude", "longitude"),
    )


class MandiPrice(Base):
    """Mandi price information model."""

    __tablename__ = "mandi_prices"

    id = Column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
        nullable=False,
    )
    mandi_id = Column(UUID(as_uuid=True), ForeignKey("mandis.id"), nullable=False)
    crop_name = Column(String(255), nullable=False)
    crop_name_local = Column(String(255), nullable=True)
    price_per_quintal = Column(Numeric(10, 2), nullable=False)
    unit = Column(String(50), default="quintal", nullable=False)
    price_date = Column(Date, nullable=False)
    min_price = Column(Numeric(10, 2), nullable=True)
    max_price = Column(Numeric(10, 2), nullable=True)
    created_at = Column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )
    updated_at = Column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    # Relationships
    mandi = relationship("Mandi", back_populates="prices")

    # Indexes
    __table_args__ = (
        Index("idx_mandi_price_mandi", "mandi_id"),
        Index("idx_mandi_price_crop", "crop_name"),
        Index("idx_mandi_price_date", "price_date"),
        Index("idx_mandi_price_mandi_crop_date", "mandi_id", "crop_name", "price_date"),
    )
