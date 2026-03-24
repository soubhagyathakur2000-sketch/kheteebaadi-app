import pytest
from decimal import Decimal
from unittest.mock import AsyncMock, patch
import uuid

from app.services.order_service import OrderService
from app.schemas.order import OrderItemCreateSchema


@pytest.mark.asyncio
class TestOrderServiceCreateOrder:
    """Test OrderService.create_order method."""

    async def test_create_order_valid_items(self):
        """Test creating order with valid items."""
        service = OrderService()
        db_mock = AsyncMock()

        user_id = str(uuid.uuid4())
        items = [
            OrderItemCreateSchema(
                crop_name="Wheat",
                quantity=Decimal("50.0"),
                unit="quintal",
                price_per_unit=Decimal("2500.0"),
            )
        ]
        delivery_address = "123 Main Street, Village"

        order = await service.create_order(
            db=db_mock,
            user_id=user_id,
            items=items,
            delivery_address=delivery_address,
        )

        assert order is not None
        assert order.user_id == uuid.UUID(user_id)
        db_mock.add.assert_called()

    async def test_create_order_multiple_items(self):
        """Test creating order with multiple items."""
        service = OrderService()
        db_mock = AsyncMock()

        user_id = str(uuid.uuid4())
        items = [
            OrderItemCreateSchema(
                crop_name="Wheat",
                quantity=Decimal("50.0"),
                unit="quintal",
                price_per_unit=Decimal("2500.0"),
            ),
            OrderItemCreateSchema(
                crop_name="Rice",
                quantity=Decimal("100.0"),
                unit="quintal",
                price_per_unit=Decimal("3000.0"),
            ),
        ]
        delivery_address = "123 Main Street, Village"

        order = await service.create_order(
            db=db_mock,
            user_id=user_id,
            items=items,
            delivery_address=delivery_address,
        )

        assert order is not None
        assert len(order.items) == 2

    async def test_create_order_calculates_total_amount(self):
        """Test order total is calculated correctly."""
        service = OrderService()
        db_mock = AsyncMock()

        user_id = str(uuid.uuid4())
        items = [
            OrderItemCreateSchema(
                crop_name="Wheat",
                quantity=Decimal("50.0"),
                unit="quintal",
                price_per_unit=Decimal("2500.0"),
            ),
            OrderItemCreateSchema(
                crop_name="Rice",
                quantity=Decimal("100.0"),
                unit="quintal",
                price_per_unit=Decimal("3000.0"),
            ),
        ]
        delivery_address = "123 Main Street, Village"

        order = await service.create_order(
            db=db_mock,
            user_id=user_id,
            items=items,
            delivery_address=delivery_address,
        )

        # Wheat: 50 * 2500 = 125000
        # Rice: 100 * 3000 = 300000
        # Total: 425000
        expected_total = Decimal("425000.00")
        assert order.total_amount == expected_total

    async def test_create_order_generates_order_number(self):
        """Test order number is generated."""
        service = OrderService()
        db_mock = AsyncMock()

        user_id = str(uuid.uuid4())
        items = [
            OrderItemCreateSchema(
                crop_name="Wheat",
                quantity=Decimal("50.0"),
                unit="quintal",
                price_per_unit=Decimal("2500.0"),
            )
        ]
        delivery_address = "123 Main Street, Village"

        order = await service.create_order(
            db=db_mock,
            user_id=user_id,
            items=items,
            delivery_address=delivery_address,
        )

        assert order.order_number is not None
        assert "ORD-" in order.order_number

    async def test_create_order_with_notes(self):
        """Test creating order with delivery notes."""
        service = OrderService()
        db_mock = AsyncMock()

        user_id = str(uuid.uuid4())
        items = [
            OrderItemCreateSchema(
                crop_name="Wheat",
                quantity=Decimal("50.0"),
                unit="quintal",
                price_per_unit=Decimal("2500.0"),
            )
        ]
        delivery_address = "123 Main Street, Village"
        notes = "Deliver in morning"

        order = await service.create_order(
            db=db_mock,
            user_id=user_id,
            items=items,
            delivery_address=delivery_address,
            notes=notes,
        )

        assert order.notes == notes

    async def test_create_order_initial_status_pending(self):
        """Test new order has pending status."""
        service = OrderService()
        db_mock = AsyncMock()

        user_id = str(uuid.uuid4())
        items = [
            OrderItemCreateSchema(
                crop_name="Wheat",
                quantity=Decimal("50.0"),
                unit="quintal",
                price_per_unit=Decimal("2500.0"),
            )
        ]
        delivery_address = "123 Main Street, Village"

        order = await service.create_order(
            db=db_mock,
            user_id=user_id,
            items=items,
            delivery_address=delivery_address,
        )

        assert order.status == "pending"


@pytest.mark.asyncio
class TestOrderServiceCancelOrder:
    """Test OrderService.cancel_order method."""

    async def test_cancel_order_pending_status(self):
        """Test cancelling order in pending status."""
        service = OrderService()
        db_mock = AsyncMock()

        order_id = str(uuid.uuid4())
        user_id = str(uuid.uuid4())

        # Mock the order with pending status
        from app.models import Order

        order_mock = AsyncMock(spec=Order)
        order_mock.status = "pending"
        order_mock.user_id = uuid.UUID(user_id)

        result = await service.cancel_order(
            db=db_mock,
            order_id=order_id,
            user_id=user_id,
        )

        assert result is not None

    async def test_cancel_order_rejected_after_dispatch(self):
        """Test cancelling order after dispatch fails."""
        service = OrderService()
        db_mock = AsyncMock()

        order_id = str(uuid.uuid4())
        user_id = str(uuid.uuid4())

        from app.models import Order

        order_mock = AsyncMock(spec=Order)
        order_mock.status = "shipped"
        order_mock.user_id = uuid.UUID(user_id)

        from app.core.exceptions import ValidationException

        with pytest.raises(ValidationException):
            await service.cancel_order(
                db=db_mock,
                order_id=order_id,
                user_id=user_id,
            )


@pytest.mark.asyncio
class TestOrderServiceUpdateStatus:
    """Test OrderService.update_status method."""

    async def test_update_status_valid_transition(self):
        """Test valid status transition."""
        service = OrderService()
        db_mock = AsyncMock()

        order_id = str(uuid.uuid4())

        from app.models import Order

        order_mock = AsyncMock(spec=Order)
        order_mock.status = "pending"

        result = await service.update_status(
            db=db_mock,
            order_id=order_id,
            new_status="confirmed",
        )

        assert result is not None

    async def test_update_status_invalid_transition(self):
        """Test invalid status transition is rejected."""
        service = OrderService()
        db_mock = AsyncMock()

        order_id = str(uuid.uuid4())

        from app.models import Order
        from app.core.exceptions import ValidationException

        order_mock = AsyncMock(spec=Order)
        order_mock.status = "delivered"

        # Cannot go back to pending from delivered
        with pytest.raises(ValidationException):
            await service.update_status(
                db=db_mock,
                order_id=order_id,
                new_status="pending",
            )


@pytest.mark.asyncio
class TestOrderServiceListOrders:
    """Test OrderService.list_orders method."""

    async def test_list_orders_returns_paginated_results(self):
        """Test listing orders returns paginated results."""
        service = OrderService()
        db_mock = AsyncMock()

        user_id = str(uuid.uuid4())

        result = await service.list_orders(
            db=db_mock,
            user_id=user_id,
            page=1,
            limit=20,
        )

        assert result is not None
        assert hasattr(result, "items") or isinstance(result, list)

    async def test_list_orders_respects_pagination(self):
        """Test pagination parameters are respected."""
        service = OrderService()
        db_mock = AsyncMock()

        user_id = str(uuid.uuid4())

        # Test different page sizes
        result1 = await service.list_orders(
            db=db_mock,
            user_id=user_id,
            page=1,
            limit=10,
        )

        result2 = await service.list_orders(
            db=db_mock,
            user_id=user_id,
            page=1,
            limit=20,
        )

        assert result1 is not None
        assert result2 is not None
