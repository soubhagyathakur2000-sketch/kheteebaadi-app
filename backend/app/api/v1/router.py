from fastapi import APIRouter

from app.api.v1.endpoints import auth, mandi, orders, sync, users, villages

api_router = APIRouter(prefix="/api/v1")

# Include endpoint routers
api_router.include_router(auth.router, prefix="/auth", tags=["auth"])
api_router.include_router(mandi.router, prefix="/mandi", tags=["mandi"])
api_router.include_router(orders.router, prefix="/orders", tags=["orders"])
api_router.include_router(sync.router, prefix="/sync", tags=["sync"])
api_router.include_router(users.router, prefix="/users", tags=["users"])
api_router.include_router(villages.router, prefix="/villages", tags=["villages"])
