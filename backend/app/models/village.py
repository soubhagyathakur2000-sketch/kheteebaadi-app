from sqlalchemy import Column, String, Float, Boolean, DateTime, Index
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from datetime import datetime, timezone
import uuid

from app.core.database import Base


class Village(Base):
    """Village model for Kheteebaadi app."""

    __tablename__ = "villages"

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
    pin_code = Column(String(10), nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    # Relationships
    users = relationship("User", back_populates="village")

    # Indexes
    __table_args__ = (
        Index("idx_village_district", "district"),
        Index("idx_village_state", "state"),
        Index("idx_village_coords", "latitude", "longitude"),
    )
