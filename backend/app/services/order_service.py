from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from datetime import datetime, timezone
from decimal import Decimal
import uuid
import structlog

from app.core.exceptions import NotFoundException, ValidationException, ForbiddenException
from app.models import Order, OrderItem, User
from app.models.order import OrderStatus
from app.schemas.order import OrderItemCreateSchema, OrderResponseSchema, OrderItemResponseSchema, OrderListSchema

logger = structlog.get_logger(__name__)


class OrderService:
    """Service for order operations."""

    async def create_order(
        self,
        db: AsyncSession,
        user_id: str,
        items: list[OrderItemCreateSchema],
        delivery_address: str,
        notes: str = None,
    ) -> OrderResponseSchema:
        """Create a new order."""
        if not items:
            raise ValidationException("Order must contain at least one item")

        # Calculate total amount
        total_amount = Decimal(0)
        for item in items:
            subtotal = item.quantity * item.price_per_unit
            total_amount += subtotal

        # Generate order number
        order_number = f"ORD-{datetime.now(timezone.utc).strftime('%Y%m%d')}-{uuid.uuid4().hex[:6].upper()}"

        # Create order
        order = Order(
            id=uuid.uuid4(),
            user_id=uuid.UUID(user_id),
            order_number=order_number,
            status=OrderStatus.PENDING,
            total_amount=total_amount,
            delivery_address=delivery_address,
            notes=notes,
        )

        db.add(order)
        await db.flush()

        # Create order items
        for item in items:
            order_item = OrderItem(
                id=uuid.uuid4(),
                order_id=order.id,
                crop_name=item.crop_name,
                quantity=item.quantity,
                unit=item.unit,
                price_per_unit=item.price_per_unit,
                subtotal=item.quantity * item.price_per_unit,
            )
            db.add(order_item)

        await db.commit()
        await db.refresh(order)

        logger.info(
            "Order created",
            order_id=str(order.id),
            user_id=user_id,
            order_number=order_number,
            total=total_amount,
        )

        return await self._order_to_response(order)

    async def get_user_orders(
        self,
        db: AsyncSession,
        user_id: str,
        status: str = None,
        page: int = 1,
        limit: int = 20,
    ) -> OrderListSchema:
        """Get user's orders."""
        query = select(Order).where(Order.user_id == uuid.UUID(user_id))

        if status:
            if status not in [s.value for s in OrderStatus]:
                raise ValidationException(f"Invalid status: {status}")
            query = query.where(Order.status == OrderStatus(status))

        # Count total
        count_result = await db.execute(
            select(func.count())
            .select_from(Order)
            .where(Order.user_id == uuid.UUID(user_id))
        )
        total = count_result.scalar() or 0

        # Paginate
        offset = (page - 1) * limit
        query = query.offset(offset).limit(limit).order_by(Order.created_at.desc())

        result = await db.execute(query)
        orders = result.scalars().all()

        items = [await self._order_to_response(order) for order in orders]

        return OrderListSchema(items=items, total=total, page=page, limit=limit)

    async def get_order_detail(
        self,
        db: AsyncSession,
        order_id: str,
        user_id: str,
    ) -> OrderResponseSchema:
        """Get order detail by ID."""
        query = select(Order).where(Order.id == uuid.UUID(order_id))
        result = await db.execute(query)
        order = result.scalars().first()

        if not order:
            raise NotFoundException("Order not found")

        if str(order.user_id) != user_id:
            raise ForbiddenException("You don't have access to this order")

        return await self._order_to_response(order)

    async def update_status(
        self,
        db: AsyncSession,
        order_id: str,
        new_status: str,
    ) -> OrderResponseSchema:
        """Update order status."""
        query = select(Order).where(Order.id == uuid.UUID(order_id))
        result = await db.execute(query)
        order = result.scalars().first()

        if not order:
            raise NotFoundException("Order not found")

        # Validate status transition
        valid_statuses = [s.value for s in OrderStatus]
        if new_status not in valid_statuses:
            raise ValidationException(f"Invalid status: {new_status}")

        order.status = OrderStatus(new_status)
        order.updated_at = datetime.now(timezone.utc)

        await db.commit()
        await db.refresh(order)

        logger.info(
            "Order status updated",
            order_id=str(order.id),
            status=new_status,
        )

        return await self._order_to_response(order)

    async def cancel_order(
        self,
        db: AsyncSession,
        order_id: str,
        user_id: str,
    ) -> OrderResponseSchema:
        """Cancel order (only if pending or confirmed)."""
        query = select(Order).where(Order.id == uuid.UUID(order_id))
        result = await db.execute(query)
        order = result.scalars().first()

        if not order:
            raise NotFoundException("Order not found")

        if str(order.user_id) != user_id:
            raise ForbiddenException("You don't have access to this order")

        # Check if order can be cancelled
        if order.status not in [OrderStatus.PENDING, OrderStatus.CONFIRMED]:
            raise ValidationException(
                f"Cannot cancel order with status: {order.status.value}"
            )

        order.status = OrderStatus.CANCELLED
        order.updated_at = datetime.now(timezone.utc)

        await db.commit()
        await db.refresh(order)

        logger.info("Order cancelled", order_id=str(order.id), user_id=user_id)

        return await self._order_to_response(order)

    async def _order_to_response(self, order: Order) -> OrderResponseSchema:
        """Convert order model to response schema."""
        items = [
            OrderItemResponseSchema(
                id=str(item.id),
                crop_name=item.crop_name,
                quantity=item.quantity,
                unit=item.unit,
                price_per_unit=item.price_per_unit,
                subtotal=item.subtotal,
            )
            for item in order.items
        ]

        return OrderResponseSchema(
            id=str(order.id),
            order_number=order.order_number,
            status=order.status.value,
            items=items,
            total_amount=order.total_amount,
            delivery_address=order.delivery_address,
            notes=order.notes,
            created_at=order.created_at,
            updated_at=order.updated_at,
        )
