from fastapi import HTTPException, status


class KheteebaadiException(HTTPException):
    """Base exception for Kheteebaadi app."""

    def __init__(
        self,
        status_code: int,
        detail: str,
        headers: dict = None,
    ):
        super().__init__(status_code=status_code, detail=detail, headers=headers)


class NotFoundException(KheteebaadiException):
    """404 Not Found exception."""

    def __init__(self, detail: str = "Resource not found"):
        super().__init__(status_code=status.HTTP_404_NOT_FOUND, detail=detail)


class UnauthorizedException(KheteebaadiException):
    """401 Unauthorized exception."""

    def __init__(self, detail: str = "Unauthorized"):
        super().__init__(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=detail,
            headers={"WWW-Authenticate": "Bearer"},
        )


class ForbiddenException(KheteebaadiException):
    """403 Forbidden exception."""

    def __init__(self, detail: str = "Forbidden"):
        super().__init__(status_code=status.HTTP_403_FORBIDDEN, detail=detail)


class ConflictException(KheteebaadiException):
    """409 Conflict exception."""

    def __init__(self, detail: str = "Conflict"):
        super().__init__(status_code=status.HTTP_409_CONFLICT, detail=detail)


class ValidationException(KheteebaadiException):
    """422 Validation error exception."""

    def __init__(self, detail: str = "Validation error"):
        super().__init__(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail=detail)


class RateLimitException(KheteebaadiException):
    """429 Rate limit exceeded exception."""

    def __init__(self, detail: str = "Rate limit exceeded"):
        super().__init__(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail=detail,
            headers={"Retry-After": "60"},
        )


class SyncConflictException(KheteebaadiException):
    """409 Sync conflict exception for duplicate sync items."""

    def __init__(self, detail: str = "Sync item already processed"):
        super().__init__(status_code=status.HTTP_409_CONFLICT, detail=detail)
