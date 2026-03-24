from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from datetime import datetime, timezone
import uuid
import structlog

from app.core.exceptions import NotFoundException
from app.models import User, Order
from app.schemas.auth import UserResponseSchema

logger = structlog.get_logger(__name__)


class UserService:
    """Service for user operations."""

    async def get_user_profile(
        self,
        db: AsyncSession,
        user_id: str,
    ) -> UserResponseSchema:
        """Get user profile."""
        query = select(User).where(User.id == uuid.UUID(user_id))
        result = await db.execute(query)
        user = result.scalars().first()

        if not user:
            raise NotFoundException("User not found")

        return UserResponseSchema(
            id=str(user.id),
            name=user.name,
            phone=user.phone,
            village_id=str(user.village_id) if user.village_id else None,
            language_pref=user.language_pref,
            avatar_url=user.avatar_url,
        )

    async def update_user_profile(
        self,
        db: AsyncSession,
        user_id: str,
        name: str = None,
        language_pref: str = None,
    ) -> UserResponseSchema:
        """Update user profile."""
        query = select(User).where(User.id == uuid.UUID(user_id))
        result = await db.execute(query)
        user = result.scalars().first()

        if not user:
            raise NotFoundException("User not found")

        if name is not None:
            user.name = name

        if language_pref is not None:
            user.language_pref = language_pref

        user.updated_at = datetime.now(timezone.utc)

        await db.commit()
        await db.refresh(user)

        logger.info("User profile updated", user_id=user_id)

        return UserResponseSchema(
            id=str(user.id),
            name=user.name,
            phone=user.phone,
            village_id=str(user.village_id) if user.village_id else None,
            language_pref=user.language_pref,
            avatar_url=user.avatar_url,
        )

    async def get_user_stats(
        self,
        db: AsyncSession,
        user_id: str,
    ) -> dict:
        """Get user statistics."""
        # Count total orders
        order_count_result = await db.execute(
            select(func.count()).select_from(Order).where(Order.user_id == uuid.UUID(user_id))
        )
        order_count = order_count_result.scalar() or 0

        # Sum total spent
        total_spent_result = await db.execute(
            select(func.sum(Order.total_amount))
            .select_from(Order)
            .where(Order.user_id == uuid.UUID(user_id))
        )
        total_spent = total_spent_result.scalar() or 0

        # Get recent orders
        query = (
            select(Order)
            .where(Order.user_id == uuid.UUID(user_id))
            .order_by(Order.created_at.desc())
            .limit(5)
        )
        result = await db.execute(query)
        recent_orders = result.scalars().all()

        logger.info(
            "User stats retrieved",
            user_id=user_id,
            order_count=order_count,
            total_spent=total_spent,
        )

        return {
            "order_count": order_count,
            "total_spent": float(total_spent),
            "recent_orders": [
                {
                    "id": str(order.id),
                    "order_number": order.order_number,
                    "status": order.status.value,
                    "total_amount": float(order.total_amount),
                    "created_at": order.created_at.isoformat(),
                }
                for order in recent_orders
            ],
        }
