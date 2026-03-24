from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.security import get_current_user
from app.schemas.order import (
    OrderCreateSchema,
    OrderResponseSchema,
    OrderListSchema,
    OrderStatusUpdateSchema,
)
from app.services.order_service import OrderService

router = APIRouter()
order_service = OrderService()


@router.post("", response_model=OrderResponseSchema, status_code=201)
async def create_order(
    order_data: OrderCreateSchema,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Create a new order."""
    return await order_service.create_order(
        db=db,
        user_id=current_user.get("user_id"),
        items=order_data.items,
        delivery_address=order_data.delivery_address,
        notes=order_data.notes,
    )


@router.get("", response_model=OrderListSchema)
async def list_user_orders(
    status: str = Query(None),
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    List user's orders with optional status filter.

    - **status**: Filter by status (pending, confirmed, processing, shipped, delivered, cancelled)
    - **page**: Page number (default: 1)
    - **limit**: Items per page (default: 20, max: 100)
    """
    return await order_service.get_user_orders(
        db=db,
        user_id=current_user.get("user_id"),
        status=status,
        page=page,
        limit=limit,
    )


@router.get("/{order_id}", response_model=OrderResponseSchema)
async def get_order_detail(
    order_id: str,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get order detail by ID."""
    return await order_service.get_order_detail(
        db=db,
        order_id=order_id,
        user_id=current_user.get("user_id"),
    )


@router.patch("/{order_id}/status", response_model=OrderResponseSchema)
async def update_order_status(
    order_id: str,
    status_update: OrderStatusUpdateSchema,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Update order status (admin/staff only)."""
    return await order_service.update_status(
        db=db,
        order_id=order_id,
        new_status=status_update.status,
    )


@router.post("/{order_id}/cancel", response_model=OrderResponseSchema)
async def cancel_order(
    order_id: str,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Cancel order (only if in pending or confirmed status)."""
    return await order_service.cancel_order(
        db=db,
        order_id=order_id,
        user_id=current_user.get("user_id"),
    )
