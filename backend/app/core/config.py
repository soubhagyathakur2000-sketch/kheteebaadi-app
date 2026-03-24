from pydantic_settings import BaseSettings
from typing import Optional


class Settings(BaseSettings):
    # App info
    APP_NAME: str = "Kheteebaadi API"
    VERSION: str = "1.0.0"
    DEBUG: bool = False

    # Database
    DATABASE_URL: str = "postgresql+asyncpg://user:password@localhost/kheteebaadi"

    # Redis
    REDIS_URL: str = "redis://localhost:6379/0"

    # JWT
    JWT_SECRET_KEY: str
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30

    # OTP
    OTP_EXPIRE_SECONDS: int = 300
    OTP_LENGTH: int = 6
    OTP_MAX_ATTEMPTS_PER_HOUR: int = 3

    # AWS S3
    AWS_REGION: str = "ap-south-1"
    S3_BUCKET: str = "kheteebaadi"
    AWS_ACCESS_KEY_ID: Optional[str] = None
    AWS_SECRET_ACCESS_KEY: Optional[str] = None

    # CORS
    CORS_ORIGINS: list = [
        "http://localhost:3000",
        "http://localhost:8081",
        "http://10.0.2.2:8000",
        "https://localhost",
        "https://api.kheteebaadi.com",
        "https://kheteebaadi.in",
        "capacitor://localhost",
        "ionic://localhost",
        "*",  # Flutter mobile apps send no Origin header; wildcard ensures compatibility
    ]

    # Sync
    SYNC_BATCH_MAX_SIZE: int = 50
    SYNC_IDEMPOTENCY_TTL_HOURS: int = 72

    # Cache
    CACHE_TTL_MANDI_PRICES: int = 900  # 15 minutes
    CACHE_TTL_VILLAGES: int = 3600  # 1 hour
    CACHE_TTL_MANDIS: int = 3600  # 1 hour

    # Rate limiting
    RATE_LIMIT_PER_MINUTE: int = 100

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        case_sensitive = True


settings = Settings()
