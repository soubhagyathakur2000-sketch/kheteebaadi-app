from fastapi import Request, HTTPException, status
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import Response
from app.core.redis import get_redis
from app.core.config import settings
from app.core.security import decode_token
import time
import structlog

logger = structlog.get_logger(__name__)


class RateLimitMiddleware(BaseHTTPMiddleware):
    """
    Redis-based sliding window rate limiter middleware.

    Per-user rate limiting using JWT user_id from token.
    Default: 100 requests per minute per user.
    """

    async def dispatch(self, request: Request, call_next) -> Response:
        """Process request with rate limiting."""
        # Skip rate limiting for certain paths
        if request.url.path in ["/health", "/api/v1"]:
            return await call_next(request)

        # Extract user_id from JWT if present
        user_id = self._extract_user_id(request)
        if not user_id:
            # No auth token, allow but don't track
            return await call_next(request)

        # Check rate limit
        try:
            redis_client = await get_redis()
            current_time = int(time.time())
            window_start = current_time - 60  # 1 minute window

            rate_limit_key = f"rate_limit:{user_id}"

            # Get all timestamps in current window
            timestamps = await redis_client.client.zrange(
                rate_limit_key, window_start, current_time
            )

            if len(timestamps) >= settings.RATE_LIMIT_PER_MINUTE:
                logger.warning(
                    "Rate limit exceeded",
                    user_id=user_id,
                    count=len(timestamps),
                )
                raise HTTPException(
                    status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                    detail="Rate limit exceeded",
                    headers={"Retry-After": "60"},
                )

            # Add current timestamp
            await redis_client.client.zadd(rate_limit_key, {str(current_time): current_time})

            # Set expiration
            await redis_client.client.expire(rate_limit_key, 120)

        except HTTPException:
            raise
        except Exception as e:
            logger.error("Rate limiter error", error=str(e))
            # Allow request on redis error

        response = await call_next(request)
        return response

    @staticmethod
    def _extract_user_id(request: Request) -> str:
        """Extract user_id from JWT token in Authorization header."""
        auth_header = request.headers.get("Authorization", "")
        if not auth_header.startswith("Bearer "):
            return None

        token = auth_header[7:]
        try:
            payload = decode_token(token)
            return payload.get("sub")
        except Exception:
            return None
