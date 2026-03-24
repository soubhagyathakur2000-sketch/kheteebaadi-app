from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.core.database import get_db
from app.core.redis import get_redis, RedisClient
from app.core.security import (
    create_access_token,
    create_refresh_token,
    decode_token,
    generate_otp,
    verify_otp,
    get_current_user,
)
from app.core.exceptions import UnauthorizedException, ValidationException
from app.models import User
from app.schemas.auth import (
    OtpRequestSchema,
    OtpVerifySchema,
    TokenResponseSchema,
    RefreshTokenSchema,
    UserResponseSchema,
)
from app.services.otp_service import OtpService
from datetime import timedelta

router = APIRouter()
otp_service = OtpService()


@router.post("/otp/request", status_code=200)
async def request_otp(
    request: OtpRequestSchema,
    redis_client: RedisClient = Depends(get_redis),
):
    """Request OTP for phone number."""
    await otp_service.generate_and_store(request.phone, redis_client)
    return {
        "message": "OTP sent successfully",
        "phone": request.phone,
        "expires_in": 300,
    }


@router.post("/otp/verify", response_model=TokenResponseSchema)
async def verify_otp_and_login(
    request: OtpVerifySchema,
    db: AsyncSession = Depends(get_db),
    redis_client: RedisClient = Depends(get_redis),
):
    """Verify OTP and create/return user with tokens."""
    # Verify OTP
    is_valid = await verify_otp(request.phone, request.otp, redis_client)
    if not is_valid:
        raise ValidationException("Invalid or expired OTP")

    # Get or create user
    stmt = select(User).where(User.phone == request.phone)
    result = await db.execute(stmt)
    user = result.scalars().first()

    if not user:
        user = User(phone=request.phone, language_pref="hi")
        db.add(user)
        await db.commit()
        await db.refresh(user)

    # Generate tokens
    access_token = create_access_token(
        data={"sub": str(user.id)},
        expires_delta=timedelta(minutes=30),
    )
    refresh_token = create_refresh_token(data={"sub": str(user.id)})

    # Store refresh token in Redis
    await redis_client.set_cached(
        f"refresh_token:{user.id}", refresh_token, ttl=30 * 24 * 60 * 60
    )

    user_response = UserResponseSchema(
        id=str(user.id),
        name=user.name,
        phone=user.phone,
        village_id=str(user.village_id) if user.village_id else None,
        language_pref=user.language_pref,
        avatar_url=user.avatar_url,
    )

    return TokenResponseSchema(
        access_token=access_token,
        refresh_token=refresh_token,
        token_type="bearer",
        user=user_response,
        expires_in=1800,
    )


@router.post("/refresh", response_model=TokenResponseSchema)
async def refresh_access_token(
    request: RefreshTokenSchema,
    db: AsyncSession = Depends(get_db),
    redis_client: RedisClient = Depends(get_redis),
):
    """Refresh access token using refresh token."""
    try:
        payload = decode_token(request.refresh_token)
    except Exception:
        raise UnauthorizedException("Invalid refresh token")

    user_id = payload.get("sub")
    token_type = payload.get("type")

    if token_type != "refresh":
        raise UnauthorizedException("Invalid token type")

    # Verify refresh token in Redis
    stored_token = await redis_client.get_cached(f"refresh_token:{user_id}")
    if stored_token != request.refresh_token:
        raise UnauthorizedException("Refresh token revoked")

    # Get user
    stmt = select(User).where(User.id == user_id)
    result = await db.execute(stmt)
    user = result.scalars().first()

    if not user:
        raise UnauthorizedException("User not found")

    # Generate new access token
    access_token = create_access_token(
        data={"sub": user_id},
        expires_delta=timedelta(minutes=30),
    )

    user_response = UserResponseSchema(
        id=str(user.id),
        name=user.name,
        phone=user.phone,
        village_id=str(user.village_id) if user.village_id else None,
        language_pref=user.language_pref,
        avatar_url=user.avatar_url,
    )

    return TokenResponseSchema(
        access_token=access_token,
        refresh_token=request.refresh_token,
        token_type="bearer",
        user=user_response,
        expires_in=1800,
    )


@router.post("/logout", status_code=200)
async def logout(
    current_user: dict = Depends(get_current_user),
    redis_client: RedisClient = Depends(get_redis),
):
    """Logout and blacklist refresh token."""
    user_id = current_user.get("user_id")
    await redis_client.delete_cached(f"refresh_token:{user_id}")
    return {"message": "Logged out successfully"}
