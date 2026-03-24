from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.services.village_service import VillageService

router = APIRouter()
village_service = VillageService()


@router.get("")
async def list_villages(
    search: str = Query(None),
    state: str = Query(None),
    district: str = Query(None),
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
):
    """
    List villages with search and filters.

    - **search**: Search by village name
    - **state**: Filter by state
    - **district**: Filter by district
    - **page**: Page number (default: 1)
    - **limit**: Items per page (default: 20, max: 100)
    """
    return await village_service.list_villages(
        db=db,
        search=search,
        state=state,
        district=district,
        page=page,
        limit=limit,
    )


@router.get("/{village_id}")
async def get_village_detail(
    village_id: str,
    db: AsyncSession = Depends(get_db),
):
    """Get village detail by ID."""
    return await village_service.get_village_detail(db=db, village_id=village_id)


@router.get("/nearby")
async def get_nearby_villages(
    latitude: float = Query(...),
    longitude: float = Query(...),
    radius_km: float = Query(50, ge=1, le=500),
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
):
    """
    Get villages near specified coordinates.

    - **latitude**: Latitude of center point
    - **longitude**: Longitude of center point
    - **radius_km**: Search radius in kilometers (default: 50, max: 500)
    - **page**: Page number (default: 1)
    - **limit**: Items per page (default: 20, max: 100)
    """
    return await village_service.get_nearby_villages(
        db=db,
        latitude=latitude,
        longitude=longitude,
        radius_km=radius_km,
        page=page,
        limit=limit,
    )
