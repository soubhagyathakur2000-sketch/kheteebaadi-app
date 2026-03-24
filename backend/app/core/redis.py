import json
import redis.asyncio as redis
from typing import Any, Optional
from contextlib import asynccontextmanager

from app.core.config import settings


class RedisClient:
    """Redis client with JSON serialization support."""

    def __init__(self):
        self.redis_pool: Optional[redis.ConnectionPool] = None
        self.client: Optional[redis.Redis] = None

    async def connect(self):
        """Create Redis connection pool."""
        self.redis_pool = redis.ConnectionPool.from_url(
            settings.REDIS_URL, decode_responses=True, max_connections=20
        )
        self.client = redis.Redis(connection_pool=self.redis_pool)
        await self.client.ping()

    async def disconnect(self):
        """Close Redis connection."""
        if self.client:
            await self.client.close()
        if self.redis_pool:
            await self.redis_pool.disconnect()

    async def get_cached(self, key: str) -> Optional[Any]:
        """Get cached value with JSON deserialization."""
        if not self.client:
            return None
        value = await self.client.get(key)
        if value:
            try:
                return json.loads(value)
            except (json.JSONDecodeError, TypeError):
                return value
        return None

    async def set_cached(self, key: str, value: Any, ttl: int = 3600) -> bool:
        """Set cached value with JSON serialization."""
        if not self.client:
            return False
        try:
            serialized = json.dumps(value)
            await self.client.setex(key, ttl, serialized)
            return True
        except (TypeError, ValueError):
            return False

    async def delete_cached(self, key: str) -> int:
        """Delete cached value."""
        if not self.client:
            return 0
        return await self.client.delete(key)

    async def exists(self, key: str) -> bool:
        """Check if key exists."""
        if not self.client:
            return False
        return bool(await self.client.exists(key))

    async def increment(self, key: str, amount: int = 1) -> int:
        """Increment counter."""
        if not self.client:
            return 0
        return await self.client.incr(key, amount)

    async def expire(self, key: str, ttl: int) -> bool:
        """Set expiration on key."""
        if not self.client:
            return False
        return await self.client.expire(key, ttl)

    async def get_many(self, keys: list[str]) -> dict[str, Any]:
        """Get multiple values."""
        if not self.client:
            return {}
        values = await self.client.mget(keys)
        result = {}
        for key, value in zip(keys, values):
            if value:
                try:
                    result[key] = json.loads(value)
                except (json.JSONDecodeError, TypeError):
                    result[key] = value
        return result

    async def set_many(self, mapping: dict[str, Any], ttl: int = 3600):
        """Set multiple values."""
        if not self.client:
            return
        pipe = self.client.pipeline()
        for key, value in mapping.items():
            try:
                serialized = json.dumps(value)
                pipe.setex(key, ttl, serialized)
            except (TypeError, ValueError):
                pass
        await pipe.execute()

    async def flushdb(self):
        """Flush all keys in current database."""
        if self.client:
            await self.client.flushdb()


# Global Redis client instance
redis_client = RedisClient()


async def get_redis() -> RedisClient:
    """Dependency to get Redis client."""
    if not redis_client.client:
        await redis_client.connect()
    return redis_client


@asynccontextmanager
async def redis_connection():
    """Context manager for Redis connection."""
    client = await get_redis()
    try:
        yield client
    finally:
        pass
