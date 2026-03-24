from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.security import get_current_user
from app.schemas.auth import UserResponseSchema, UserUpdateSchema
from app.services.user_service import UserService

router = APIRouter()
user_service = UserService()


@router.get("/me", response_model=UserResponseSchema)
async def get_current_user_profile(
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get current user's profile."""
    return await user_service.get_user_profile(
        db=db,
        user_id=current_user.get("user_id"),
    )


@router.patch("/me", response_model=UserResponseSchema)
async def update_user_profile(
    user_update: UserUpdateSchema,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Update current user's profile."""
    return await user_service.update_user_profile(
        db=db,
        user_id=current_user.get("user_id"),
        name=user_update.name,
        language_pref=user_update.language_pref,
    )


@router.get("/me/stats")
async def get_user_stats(
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get user statistics (order count, total spent)."""
    return await user_service.get_user_stats(
        db=db,
        user_id=current_user.get("user_id"),
    )
