from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import Response
from starlette.types import ASGIApp
import time
import uuid
import structlog

logger = structlog.get_logger(__name__)


class LoggingMiddleware(BaseHTTPMiddleware):
    """
    Structured logging middleware using structlog.

    Logs request method, path, status, duration.
    Injects correlation/request ID.
    Skips health check endpoints.
    """

    async def dispatch(self, request: Request, call_next) -> Response:
        """Process request and log details."""
        # Skip logging for health checks
        if request.url.path == "/health":
            return await call_next(request)

        # Generate request ID
        request_id = str(uuid.uuid4())
        request.state.request_id = request_id

        # Record start time
        start_time = time.time()

        # Call next middleware/route
        try:
            response = await call_next(request)
        except Exception as e:
            duration = (time.time() - start_time) * 1000
            logger.error(
                "request_error",
                request_id=request_id,
                method=request.method,
                path=request.url.path,
                duration_ms=round(duration, 2),
                error=str(e),
            )
            raise

        # Calculate duration
        duration = (time.time() - start_time) * 1000

        # Log request
        log_level = "info"
        if response.status_code >= 500:
            log_level = "error"
        elif response.status_code >= 400:
            log_level = "warning"
        elif duration > 1000:  # Log slow requests as warnings
            log_level = "warning"

        log_func = getattr(logger, log_level)
        log_func(
            "request",
            request_id=request_id,
            method=request.method,
            path=request.url.path,
            status_code=response.status_code,
            duration_ms=round(duration, 2),
        )

        # Add request ID to response headers
        response.headers["X-Request-ID"] = request_id

        return response
