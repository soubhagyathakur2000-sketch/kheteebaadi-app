import pytest
import asyncio
import uuid
from datetime import datetime, timezone
from decimal import Decimal
from unittest.mock import AsyncMock, MagicMock, patch
from typing import AsyncGenerator

import fakeredis.aioredis
from httpx import AsyncClient, ASGITransport
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker

from app.main import app
from app.core.config import settings
from app.core.database import Base, get_db
from app.core.redis import get_redis, RedisClient
from app.core.security import create_access_token, hash_password
from app.models import User, Village, Order, OrderItem


@pytest.fixture(scope="session")
def event_loop():
    """Create event loop for async tests."""
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    yield loop
    loop.close()


@pytest.fixture
async def test_db():
    """Create test database with SQLite in-memory."""
    database_url = "sqlite+aiosqlite:///:memory:"
    engine = create_async_engine(
        database_url,
        echo=False,
        connect_args={"check_same_thread": False},
    )

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    async_session = sessionmaker(
        engine, class_=AsyncSession, expire_on_commit=False
    )

    async def override_get_db() -> AsyncGenerator[AsyncSession, None]:
        async with async_session() as session:
            yield session

    app.dependency_overrides[get_db] = override_get_db

    yield async_session

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)

    await engine.dispose()

    app.dependency_overrides.clear()


@pytest.fixture
async def test_redis():
    """Create mock Redis client using fakeredis."""
    redis_client = fakeredis.aioredis.FakeRedis()

    async def override_get_redis() -> RedisClient:
        mock_redis = AsyncMock(spec=RedisClient)
        storage = {}

        async def get_cached(key: str):
            return storage.get(key)

        async def set_cached(key: str, value: str, ttl: int = 3600):
            storage[key] = value

        async def delete_cached(key: str):
            if key in storage:
                del storage[key]

        async def exists(key: str) -> bool:
            return key in storage

        async def increment(key: str, amount: int = 1):
            current = storage.get(key, "0")
            storage[key] = str(int(current) + amount)

        mock_redis.get_cached = get_cached
        mock_redis.set_cached = set_cached
        mock_redis.delete_cached = delete_cached
        mock_redis.exists = exists
        mock_redis.increment = increment

        return mock_redis

    app.dependency_overrides[get_redis] = override_get_redis

    yield

    app.dependency_overrides.pop(get_redis, None)


@pytest.fixture
async def test_app(test_db, test_redis):
    """Create test app with mocked dependencies."""
    async with AsyncClient(
        app=app,
        base_url="http://test",
        transport=ASGITransport(app=app),
    ) as client:
        yield client


@pytest.fixture
async def sample_village(test_db):
    """Create sample village for tests."""
    async with test_db() as session:
        village = Village(
            id=uuid.uuid4(),
            name="Test Village",
            state="Maharashtra",
            district="Pune",
            block="Haveli",
            latitude=18.5204,
            longitude=73.8567,
        )
        session.add(village)
        await session.commit()
        await session.refresh(village)
        return village


@pytest.fixture
async def sample_user(test_db, sample_village):
    """Create sample user for tests."""
    async with test_db() as session:
        user = User(
            id=uuid.uuid4(),
            phone="+919876543210",
            name="Test Farmer",
            village_id=sample_village.id,
            language_pref="hi",
            password_hash=hash_password("test_password"),
        )
        session.add(user)
        await session.commit()
        await session.refresh(user)
        return user


@pytest.fixture
async def sample_order(test_db, sample_user):
    """Create sample order for tests."""
    async with test_db() as session:
        order = Order(
            id=uuid.uuid4(),
            order_number=f"ORD-{datetime.now(timezone.utc).strftime('%Y%m%d')}-001",
            user_id=sample_user.id,
            status="pending",
            total_amount=Decimal("125000.00"),
            delivery_address="123 Main Street, Test Village",
            notes="Test order",
        )
        session.add(order)

        item = OrderItem(
            id=uuid.uuid4(),
            order_id=order.id,
            crop_name="Wheat",
            quantity=Decimal("50.00"),
            unit="quintal",
            price_per_unit=Decimal("2500.00"),
            subtotal=Decimal("125000.00"),
        )
        session.add(item)

        await session.commit()
        await session.refresh(order)
        return order


@pytest.fixture
def auth_headers(sample_user) -> dict:
    """Generate JWT auth headers for authenticated requests."""
    access_token = create_access_token(data={"sub": str(sample_user.id)})
    return {"Authorization": f"Bearer {access_token}"}


@pytest.fixture
def sample_sync_item() -> dict:
    """Generate sample sync item."""
    return {
        "entity_type": "order",
        "entity_id": "local_order_1",
        "action": "create",
        "payload": {
            "items": [
                {
                    "crop_name": "Wheat",
                    "quantity": 50.0,
                    "unit": "quintal",
                    "price_per_unit": 2500.0,
                }
            ],
            "delivery_address": "123 Main Street, Test Village",
            "notes": "Test sync order",
        },
        "idempotency_key": f"test_order_{uuid.uuid4()}",
    }


@pytest.fixture
def sample_sync_batch(sample_sync_item) -> dict:
    """Generate sample sync batch request."""
    items = [sample_sync_item]
    for i in range(2, 6):
        items.append({
            "entity_type": "order",
            "entity_id": f"local_order_{i}",
            "action": "create",
            "payload": {
                "items": [
                    {
                        "crop_name": f"Crop_{i}",
                        "quantity": 100.0,
                        "unit": "quintal",
                        "price_per_unit": 3000.0 + (i * 100),
                    }
                ],
                "delivery_address": f"{i}00 Main Street, Test Village",
                "notes": f"Sync order {i}",
            },
            "idempotency_key": f"test_order_{i}_{uuid.uuid4()}",
        })
    return {"items": items}
