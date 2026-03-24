from app.core.security import generate_otp
from app.core.redis import RedisClient
from app.core.config import settings
from app.core.exceptions import ValidationException
import structlog

logger = structlog.get_logger(__name__)


class OtpService:
    """Service for OTP operations."""

    async def generate_and_store(
        self, phone: str, redis_client: RedisClient
    ) -> str:
        """
        Generate OTP and store in Redis with rate limiting.

        Args:
            phone: Phone number
            redis_client: Redis client

        Returns:
            Generated OTP

        Raises:
            ValidationException: If rate limit exceeded
        """
        # Check rate limit: max 3 OTP requests per hour
        rate_limit_key = f"otp_requests:{phone}"
        request_count = await redis_client.get_cached(rate_limit_key)

        if request_count and int(request_count) >= settings.OTP_MAX_ATTEMPTS_PER_HOUR:
            logger.warning(
                "OTP rate limit exceeded",
                phone=phone,
                count=request_count,
            )
            raise ValidationException(
                "Too many OTP requests. Please try again after 1 hour."
            )

        # Generate OTP
        otp = generate_otp()

        # Store OTP
        await redis_client.set_cached(
            f"otp:{phone}", otp, ttl=settings.OTP_EXPIRE_SECONDS
        )

        # Increment rate limit counter
        if request_count:
            await redis_client.increment(rate_limit_key, 1)
        else:
            await redis_client.set_cached(rate_limit_key, 1, ttl=3600)

        logger.info("OTP generated", phone=phone)

        # In production, send via SMS gateway (MSG91, Twilio, etc.)
        # For development, return OTP in response
        if settings.DEBUG:
            return otp
        return "OTP_SENT"

    async def verify(self, phone: str, otp: str, redis_client: RedisClient) -> bool:
        """
        Verify OTP.

        Args:
            phone: Phone number
            otp: OTP to verify
            redis_client: Redis client

        Returns:
            True if valid, False otherwise
        """
        stored_otp = await redis_client.get_cached(f"otp:{phone}")
        if stored_otp and stored_otp == otp:
            await redis_client.delete_cached(f"otp:{phone}")
            logger.info("OTP verified", phone=phone)
            return True

        logger.warning("OTP verification failed", phone=phone)
        return False
