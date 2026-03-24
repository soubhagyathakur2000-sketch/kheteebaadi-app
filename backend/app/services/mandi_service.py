from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_, func
from decimal import Decimal
import math
import structlog

from app.core.redis import RedisClient
from app.core.config import settings
from app.core.exceptions import NotFoundException
from app.models import Mandi, MandiPrice
from app.schemas.mandi import MandiPriceSchema, MandiPriceListSchema

logger = structlog.get_logger(__name__)


class MandiService:
    """Service for mandi operations."""

    async def get_prices(
        self,
        db: AsyncSession,
        redis_client: RedisClient,
        region_id: str = None,
        crop_name: str = None,
        page: int = 1,
        limit: int = 20,
    ) -> MandiPriceListSchema:
        """
        Get mandi prices with caching.

        Cache key: mandi_prices:{region_id}:{crop_name}:{page}:{limit}
        """
        # Build cache key
        cache_key = f"mandi_prices:{region_id}:{crop_name}:{page}:{limit}"

        # Try cache first
        cached = await redis_client.get_cached(cache_key)
        if cached:
            logger.info("Mandi prices from cache", cache_key=cache_key)
            return MandiPriceListSchema(
                **cached,
                cached=True,
                cache_age_seconds=settings.CACHE_TTL_MANDI_PRICES,
            )

        # Query database
        query = select(MandiPrice).join(Mandi).where(Mandi.is_active == True)

        if region_id:
            query = query.where(Mandi.state == region_id)

        if crop_name:
            query = query.where(MandiPrice.crop_name.ilike(f"%{crop_name}%"))

        # Count total
        count_query = select(func.count()).select_from(MandiPrice).select_from(Mandi)
        if region_id:
            count_query = count_query.where(Mandi.state == region_id)
        if crop_name:
            count_query = count_query.where(MandiPrice.crop_name.ilike(f"%{crop_name}%"))

        total_result = await db.execute(count_query)
        total = total_result.scalar() or 0

        # Paginate
        offset = (page - 1) * limit
        query = query.offset(offset).limit(limit).order_by(MandiPrice.price_date.desc())

        result = await db.execute(query)
        prices = result.scalars().all()

        # Build response
        items = []
        for price in prices:
            item = MandiPriceSchema(
                id=str(price.id),
                crop_name=price.crop_name,
                crop_name_local=price.crop_name_local,
                price_per_quintal=price.price_per_quintal,
                mandi_name=price.mandi.name,
                mandi_id=str(price.mandi_id),
                price_date=price.price_date,
                min_price=price.min_price,
                max_price=price.max_price,
                unit=price.unit,
            )
            items.append(item)

        response_data = {
            "items": [item.model_dump() for item in items],
            "total": total,
            "page": page,
            "limit": limit,
        }

        # Cache result
        await redis_client.set_cached(
            cache_key, response_data, ttl=settings.CACHE_TTL_MANDI_PRICES
        )

        logger.info(
            "Mandi prices from database",
            region_id=region_id,
            crop_name=crop_name,
            total=total,
        )

        return MandiPriceListSchema(
            items=items,
            total=total,
            page=page,
            limit=limit,
            cached=False,
        )

    async def get_prices_by_mandi(
        self,
        db: AsyncSession,
        redis_client: RedisClient,
        mandi_id: str,
        page: int = 1,
        limit: int = 20,
    ) -> MandiPriceListSchema:
        """Get prices for a specific mandi."""
        cache_key = f"mandi_prices_by_mandi:{mandi_id}:{page}:{limit}"

        cached = await redis_client.get_cached(cache_key)
        if cached:
            return MandiPriceListSchema(
                **cached,
                cached=True,
                cache_age_seconds=settings.CACHE_TTL_MANDI_PRICES,
            )

        query = select(MandiPrice).where(MandiPrice.mandi_id == mandi_id)

        # Count total
        count_result = await db.execute(
            select(func.count()).select_from(MandiPrice).where(MandiPrice.mandi_id == mandi_id)
        )
        total = count_result.scalar() or 0

        # Paginate
        offset = (page - 1) * limit
        query = query.offset(offset).limit(limit).order_by(MandiPrice.price_date.desc())

        result = await db.execute(query)
        prices = result.scalars().all()

        if not prices and page == 1:
            raise NotFoundException(f"Mandi {mandi_id} not found")

        # Fetch mandi name
        mandi_query = select(Mandi).where(Mandi.id == mandi_id)
        mandi_result = await db.execute(mandi_query)
        mandi = mandi_result.scalars().first()

        items = []
        for price in prices:
            item = MandiPriceSchema(
                id=str(price.id),
                crop_name=price.crop_name,
                crop_name_local=price.crop_name_local,
                price_per_quintal=price.price_per_quintal,
                mandi_name=mandi.name if mandi else "Unknown",
                mandi_id=str(price.mandi_id),
                price_date=price.price_date,
                min_price=price.min_price,
                max_price=price.max_price,
                unit=price.unit,
            )
            items.append(item)

        response_data = {
            "items": [item.model_dump() for item in items],
            "total": total,
            "page": page,
            "limit": limit,
        }

        await redis_client.set_cached(
            cache_key, response_data, ttl=settings.CACHE_TTL_MANDI_PRICES
        )

        return MandiPriceListSchema(
            items=items,
            total=total,
            page=page,
            limit=limit,
            cached=False,
        )

    async def search_crops(
        self,
        db: AsyncSession,
        redis_client: RedisClient,
        query: str,
        region_id: str = None,
        page: int = 1,
        limit: int = 20,
    ):
        """Search for crops by name."""
        cache_key = f"crop_search:{query}:{region_id}:{page}:{limit}"

        cached = await redis_client.get_cached(cache_key)
        if cached:
            return MandiPriceListSchema(
                **cached,
                cached=True,
                cache_age_seconds=settings.CACHE_TTL_MANDI_PRICES,
            )

        search_query = select(MandiPrice).join(Mandi).where(Mandi.is_active == True)

        # Search in both English and local names
        search_query = search_query.where(
            (MandiPrice.crop_name.ilike(f"%{query}%"))
            | (MandiPrice.crop_name_local.ilike(f"%{query}%"))
        )

        if region_id:
            search_query = search_query.where(Mandi.state == region_id)

        # Count total
        count_result = await db.execute(
            select(func.count())
            .select_from(MandiPrice)
            .join(Mandi)
            .where(Mandi.is_active == True)
            .where(
                (MandiPrice.crop_name.ilike(f"%{query}%"))
                | (MandiPrice.crop_name_local.ilike(f"%{query}%"))
            )
        )
        total = count_result.scalar() or 0

        # Paginate
        offset = (page - 1) * limit
        search_query = (
            search_query.offset(offset).limit(limit).order_by(MandiPrice.price_date.desc())
        )

        result = await db.execute(search_query)
        prices = result.scalars().all()

        items = []
        for price in prices:
            item = MandiPriceSchema(
                id=str(price.id),
                crop_name=price.crop_name,
                crop_name_local=price.crop_name_local,
                price_per_quintal=price.price_per_quintal,
                mandi_name=price.mandi.name,
                mandi_id=str(price.mandi_id),
                price_date=price.price_date,
                min_price=price.min_price,
                max_price=price.max_price,
                unit=price.unit,
            )
            items.append(item)

        response_data = {
            "items": [item.model_dump() for item in items],
            "total": total,
            "page": page,
            "limit": limit,
        }

        await redis_client.set_cached(
            cache_key, response_data, ttl=settings.CACHE_TTL_MANDI_PRICES
        )

        return MandiPriceListSchema(
            items=items,
            total=total,
            page=page,
            limit=limit,
            cached=False,
        )

    async def get_nearby_mandis(
        self,
        db: AsyncSession,
        latitude: float,
        longitude: float,
        radius_km: float = 50,
    ):
        """Get mandis within radius using Haversine formula."""
        query = select(Mandi).where(Mandi.is_active == True)
        result = await db.execute(query)
        all_mandis = result.scalars().all()

        # Filter by distance using Haversine formula
        nearby = []
        for mandi in all_mandis:
            distance = self._haversine_distance(
                latitude, longitude, mandi.latitude, mandi.longitude
            )
            if distance <= radius_km:
                nearby.append(
                    {
                        "id": str(mandi.id),
                        "name": mandi.name,
                        "name_local": mandi.name_local,
                        "district": mandi.district,
                        "state": mandi.state,
                        "latitude": mandi.latitude,
                        "longitude": mandi.longitude,
                        "distance_km": round(distance, 2),
                    }
                )

        # Sort by distance
        nearby.sort(key=lambda x: x["distance_km"])

        return {
            "items": nearby,
            "total": len(nearby),
            "page": 1,
            "limit": len(nearby),
        }

    @staticmethod
    def _haversine_distance(
        lat1: float, lon1: float, lat2: float, lon2: float
    ) -> float:
        """Calculate distance between two coordinates in kilometers."""
        R = 6371  # Earth radius in km
        phi1 = math.radians(lat1)
        phi2 = math.radians(lat2)
        delta_phi = math.radians(lat2 - lat1)
        delta_lambda = math.radians(lon2 - lon1)

        a = math.sin(delta_phi / 2) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(
            delta_lambda / 2
        ) ** 2
        c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
        return R * c

    async def refresh_cache(
        self, redis_client: RedisClient, region_id: str = None
    ):
        """Force refresh cache for a region."""
        # Delete all related cache keys
        if region_id:
            # In production, use Redis SCAN to find and delete keys matching pattern
            logger.info("Cache refresh triggered", region_id=region_id)
        else:
            logger.info("Full cache refresh triggered")
