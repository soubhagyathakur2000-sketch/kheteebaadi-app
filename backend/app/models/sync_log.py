from sqlalchemy import Column, String, DateTime, ForeignKey, Index, Text, Enum, JSON
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from datetime import datetime, timezone
import uuid
import enum

from app.core.database import Base


class SyncStatus(str, enum.Enum):
    """Sync status enum."""

    PROCESSED = "processed"
    FAILED = "failed"
    DUPLICATE = "duplicate"


class SyncLog(Base):
    """Sync log model for tracking offline mutations."""

    __tablename__ = "sync_logs"

    id = Column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
        nullable=False,
    )
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    idempotency_key = Column(String(255), unique=True, nullable=False, index=True)
    entity_type = Column(String(100), nullable=False)
    entity_id = Column(String(255), nullable=False)
    action = Column(String(50), nullable=False)
    payload = Column(JSON, nullable=False)
    status = Column(
        Enum(SyncStatus),
        default=SyncStatus.PROCESSED,
        nullable=False,
    )
    error_message = Column(Text, nullable=True)
    processed_at = Column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    # Relationships
    user = relationship("User", back_populates="sync_logs")

    # Indexes
    __table_args__ = (
        Index("idx_sync_user", "user_id"),
        Index("idx_sync_idempotency", "idempotency_key"),
        Index("idx_sync_entity", "entity_type", "entity_id"),
        Index("idx_sync_status", "status"),
        Index("idx_sync_processed", "processed_at"),
    )
