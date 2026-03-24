from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.redis import get_redis, RedisClient
from app.schemas.mandi import MandiPriceListSchema, MandiSearchSchema
from app.services.mandi_service import MandiService

router = APIRouter()
mandi_service = MandiService()


@router.get("/prices", response_model=MandiPriceListSchema)
async def get_mandi_prices(
    region_id: str = Query(None),
    crop_name: str = Query(None),
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    redis_client: RedisClient = Depends(get_redis),
):
    """
    Get mandi prices with caching.

    - **region_id**: Filter by region/state
    - **crop_name**: Filter by crop name
    - **page**: Page number (default: 1)
    - **limit**: Items per page (default: 20, max: 100)
    """
    return await mandi_service.get_prices(
        db=db,
        redis_client=redis_client,
        region_id=region_id,
        crop_name=crop_name,
        page=page,
        limit=limit,
    )


@router.get("/prices/{mandi_id}", response_model=MandiPriceListSchema)
async def get_mandi_prices_by_id(
    mandi_id: str,
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    redis_client: RedisClient = Depends(get_redis),
):
    """Get prices for a specific mandi."""
    return await mandi_service.get_prices_by_mandi(
        db=db,
        redis_client=redis_client,
        mandi_id=mandi_id,
        page=page,
        limit=limit,
    )


@router.get("/search")
async def search_crops(
    query: str = Query(..., min_length=1, max_length=255),
    region_id: str = Query(None),
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    redis_client: RedisClient = Depends(get_redis),
):
    """
    Search for crops across mandis.

    - **query**: Search query (crop name in English or regional language)
    - **region_id**: Optional filter by region
    - **page**: Page number (default: 1)
    - **limit**: Items per page (default: 20, max: 100)
    """
    return await mandi_service.search_crops(
        db=db,
        redis_client=redis_client,
        query=query,
        region_id=region_id,
        page=page,
        limit=limit,
    )


@router.get("/nearby")
async def get_nearby_mandis(
    latitude: float = Query(...),
    longitude: float = Query(...),
    radius_km: float = Query(50, ge=1, le=500),
    db: AsyncSession = Depends(get_db),
):
    """
    Get mandis near specified coordinates.

    - **latitude**: Latitude of center point
    - **longitude**: Longitude of center point
    - **radius_km**: Search radius in kilometers (default: 50, max: 500)
    """
    return await mandi_service.get_nearby_mandis(
        db=db,
        latitude=latitude,
        longitude=longitude,
        radius_km=radius_km,
    )


@router.post("/refresh-cache/{region_id}", status_code=200)
async def refresh_cache(
    region_id: str,
    redis_client: RedisClient = Depends(get_redis),
):
    """Force refresh mandi price cache for a region."""
    await mandi_service.refresh_cache(redis_client=redis_client, region_id=region_id)
    return {"message": f"Cache refreshed for region {region_id}"}
