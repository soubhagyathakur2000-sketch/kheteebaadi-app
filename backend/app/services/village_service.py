from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, or_
from decimal import Decimal
import math
import uuid
import structlog

from app.core.exceptions import NotFoundException
from app.models import Village

logger = structlog.get_logger(__name__)


class VillageService:
    """Service for village operations."""

    async def list_villages(
        self,
        db: AsyncSession,
        search: str = None,
        state: str = None,
        district: str = None,
        page: int = 1,
        limit: int = 20,
    ) -> dict:
        """List villages with search and filters."""
        query = select(Village).where(Village.is_active == True)

        if search:
            query = query.where(
                or_(
                    Village.name.ilike(f"%{search}%"),
                    Village.name_local.ilike(f"%{search}%"),
                )
            )

        if state:
            query = query.where(Village.state == state)

        if district:
            query = query.where(Village.district == district)

        # Count total
        count_result = await db.execute(
            select(func.count()).select_from(Village).where(Village.is_active == True)
        )
        total = count_result.scalar() or 0

        # Paginate
        offset = (page - 1) * limit
        query = query.offset(offset).limit(limit).order_by(Village.name.asc())

        result = await db.execute(query)
        villages = result.scalars().all()

        items = [self._village_to_dict(v) for v in villages]

        return {
            "items": items,
            "total": total,
            "page": page,
            "limit": limit,
        }

    async def get_village_detail(
        self,
        db: AsyncSession,
        village_id: str,
    ) -> dict:
        """Get village detail by ID."""
        query = select(Village).where(Village.id == uuid.UUID(village_id))
        result = await db.execute(query)
        village = result.scalars().first()

        if not village:
            raise NotFoundException("Village not found")

        return self._village_to_dict(village)

    async def get_nearby_villages(
        self,
        db: AsyncSession,
        latitude: float,
        longitude: float,
        radius_km: float = 50,
        page: int = 1,
        limit: int = 20,
    ) -> dict:
        """Get villages within radius."""
        query = select(Village).where(Village.is_active == True)
        result = await db.execute(query)
        all_villages = result.scalars().all()

        # Filter by distance using Haversine formula
        nearby = []
        for village in all_villages:
            distance = self._haversine_distance(
                latitude, longitude, village.latitude, village.longitude
            )
            if distance <= radius_km:
                nearby.append(
                    {
                        **self._village_to_dict(village),
                        "distance_km": round(distance, 2),
                    }
                )

        # Sort by distance
        nearby.sort(key=lambda x: x["distance_km"])

        # Paginate
        offset = (page - 1) * limit
        paginated = nearby[offset : offset + limit]

        return {
            "items": paginated,
            "total": len(nearby),
            "page": page,
            "limit": limit,
        }

    @staticmethod
    def _village_to_dict(village: Village) -> dict:
        """Convert village model to dictionary."""
        return {
            "id": str(village.id),
            "name": village.name,
            "name_local": village.name_local,
            "district": village.district,
            "state": village.state,
            "latitude": village.latitude,
            "longitude": village.longitude,
            "pin_code": village.pin_code,
            "is_active": village.is_active,
            "created_at": village.created_at.isoformat(),
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
