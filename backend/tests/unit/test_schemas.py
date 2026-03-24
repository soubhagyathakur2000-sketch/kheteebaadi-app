import pytest
from decimal import Decimal
from pydantic import ValidationError

from app.schemas.auth import OtpRequestSchema, OtpVerifySchema
from app.schemas.order import OrderCreateSchema, OrderItemCreateSchema, OrderStatusUpdateSchema
from app.schemas.mandi import MandiPriceListSchema
from app.schemas.sync import SyncBatchRequestSchema, SyncItemSchema


class TestOtpRequestSchema:
    """Test OtpRequestSchema validation."""

    def test_valid_indian_phone_number(self):
        """Test valid 10-digit Indian phone number."""
        schema = OtpRequestSchema(phone="+919876543210")
        assert schema.phone == "+919876543210"

    def test_invalid_phone_too_short(self):
        """Test phone number with insufficient digits."""
        with pytest.raises(ValidationError) as exc_info:
            OtpRequestSchema(phone="+91987654321")
        assert "Invalid phone number" in str(exc_info.value)

    def test_invalid_phone_with_letters(self):
        """Test phone number containing letters."""
        with pytest.raises(ValidationError) as exc_info:
            OtpRequestSchema(phone="+91987654321a")
        assert "Invalid phone number" in str(exc_info.value)

    def test_indian_phone_format_parsing(self):
        """Test parsing of various Indian phone formats."""
        # Standard format
        schema = OtpRequestSchema(phone="9876543210")
        assert schema.phone == "+919876543210"

        # With country code
        schema = OtpRequestSchema(phone="+91-9876543210")
        assert schema.phone == "+919876543210"


class TestOtpVerifySchema:
    """Test OtpVerifySchema validation."""

    def test_valid_otp_six_digits(self):
        """Test valid 6-digit OTP."""
        schema = OtpVerifySchema(phone="+919876543210", otp="123456")
        assert schema.otp == "123456"

    def test_invalid_otp_five_digits(self):
        """Test OTP with insufficient digits."""
        with pytest.raises(ValidationError) as exc_info:
            OtpVerifySchema(phone="+919876543210", otp="12345")
        assert "ensure this value has at least 6 characters" in str(exc_info.value) or "at least 6" in str(exc_info.value)

    def test_invalid_otp_with_letters(self):
        """Test OTP containing non-digit characters."""
        with pytest.raises(ValidationError) as exc_info:
            OtpVerifySchema(phone="+919876543210", otp="12345a")
        assert "OTP must contain only digits" in str(exc_info.value)

    def test_invalid_otp_too_long(self):
        """Test OTP exceeding 6 digits."""
        with pytest.raises(ValidationError) as exc_info:
            OtpVerifySchema(phone="+919876543210", otp="1234567")
        assert "at most 6 characters" in str(exc_info.value) or "at most 6" in str(exc_info.value)


class TestOrderItemCreateSchema:
    """Test OrderItemCreateSchema validation."""

    def test_valid_order_item(self):
        """Test valid order item creation."""
        item = OrderItemCreateSchema(
            crop_name="Wheat",
            quantity=Decimal("50.0"),
            unit="quintal",
            price_per_unit=Decimal("2500.0"),
        )
        assert item.crop_name == "Wheat"
        assert item.quantity == Decimal("50.0")

    def test_invalid_zero_quantity(self):
        """Test order item with zero quantity."""
        with pytest.raises(ValidationError) as exc_info:
            OrderItemCreateSchema(
                crop_name="Wheat",
                quantity=Decimal("0.0"),
                unit="quintal",
                price_per_unit=Decimal("2500.0"),
            )
        assert "greater than 0" in str(exc_info.value)

    def test_invalid_negative_price(self):
        """Test order item with negative price."""
        with pytest.raises(ValidationError) as exc_info:
            OrderItemCreateSchema(
                crop_name="Wheat",
                quantity=Decimal("50.0"),
                unit="quintal",
                price_per_unit=Decimal("-100.0"),
            )
        assert "greater than 0" in str(exc_info.value)


class TestOrderCreateSchema:
    """Test OrderCreateSchema validation."""

    def test_valid_order_creation(self):
        """Test valid order creation with single item."""
        schema = OrderCreateSchema(
            items=[
                OrderItemCreateSchema(
                    crop_name="Wheat",
                    quantity=Decimal("50.0"),
                    unit="quintal",
                    price_per_unit=Decimal("2500.0"),
                )
            ],
            delivery_address="123 Main Street, Village, District",
        )
        assert len(schema.items) == 1
        assert schema.delivery_address == "123 Main Street, Village, District"

    def test_invalid_empty_items_list(self):
        """Test order with empty items list."""
        with pytest.raises(ValidationError) as exc_info:
            OrderCreateSchema(
                items=[],
                delivery_address="123 Main Street, Village, District",
            )
        assert "at least 1 item" in str(exc_info.value).lower()

    def test_invalid_too_many_items(self):
        """Test order exceeding maximum items (50)."""
        items = [
            OrderItemCreateSchema(
                crop_name=f"Crop_{i}",
                quantity=Decimal("50.0"),
                unit="quintal",
                price_per_unit=Decimal("2500.0"),
            )
            for i in range(51)
        ]
        with pytest.raises(ValidationError) as exc_info:
            OrderCreateSchema(
                items=items,
                delivery_address="123 Main Street, Village, District",
            )
        assert "more than 50 items" in str(exc_info.value)

    def test_invalid_short_delivery_address(self):
        """Test order with insufficient delivery address length."""
        with pytest.raises(ValidationError) as exc_info:
            OrderCreateSchema(
                items=[
                    OrderItemCreateSchema(
                        crop_name="Wheat",
                        quantity=Decimal("50.0"),
                        unit="quintal",
                        price_per_unit=Decimal("2500.0"),
                    )
                ],
                delivery_address="Short",
            )
        assert "at least 10 characters" in str(exc_info.value)


class TestOrderStatusUpdateSchema:
    """Test OrderStatusUpdateSchema validation."""

    def test_valid_status_pending(self):
        """Test valid pending status."""
        schema = OrderStatusUpdateSchema(status="pending")
        assert schema.status == "pending"

    def test_valid_status_confirmed(self):
        """Test valid confirmed status."""
        schema = OrderStatusUpdateSchema(status="confirmed")
        assert schema.status == "confirmed"

    def test_valid_status_shipped(self):
        """Test valid shipped status."""
        schema = OrderStatusUpdateSchema(status="shipped")
        assert schema.status == "shipped"

    def test_invalid_status(self):
        """Test invalid order status."""
        with pytest.raises(ValidationError) as exc_info:
            OrderStatusUpdateSchema(status="invalid_status")
        assert "pending|confirmed|processing|shipped|delivered|cancelled" in str(exc_info.value)


class TestSyncBatchRequestSchema:
    """Test SyncBatchRequestSchema validation."""

    def test_valid_sync_batch(self):
        """Test valid sync batch request."""
        schema = SyncBatchRequestSchema(
            items=[
                {
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
                        "delivery_address": "123 Main Street",
                    },
                    "idempotency_key": "key_1",
                }
            ]
        )
        assert len(schema.items) == 1

    def test_invalid_empty_batch(self):
        """Test sync batch with no items."""
        with pytest.raises(ValidationError) as exc_info:
            SyncBatchRequestSchema(items=[])
        assert "at least 1 item" in str(exc_info.value).lower()

    def test_invalid_batch_exceeds_max_size(self):
        """Test sync batch exceeding 50 items limit."""
        items = [
            {
                "entity_type": "order",
                "entity_id": f"local_order_{i}",
                "action": "create",
                "payload": {"items": [], "delivery_address": "Address"},
                "idempotency_key": f"key_{i}",
            }
            for i in range(51)
        ]
        with pytest.raises(ValidationError) as exc_info:
            SyncBatchRequestSchema(items=items)
        assert "more than 50 items" in str(exc_info.value)

    def test_valid_batch_exactly_fifty_items(self):
        """Test sync batch with exactly 50 items (maximum allowed)."""
        items = [
            {
                "entity_type": "order",
                "entity_id": f"local_order_{i}",
                "action": "create",
                "payload": {"items": [], "delivery_address": "Address"},
                "idempotency_key": f"key_{i}",
            }
            for i in range(50)
        ]
        schema = SyncBatchRequestSchema(items=items)
        assert len(schema.items) == 50


class TestSyncItemSchema:
    """Test SyncItemSchema validation."""

    def test_valid_create_action(self):
        """Test valid create action."""
        schema = SyncItemSchema(
            entity_type="order",
            entity_id="local_order_1",
            action="create",
            payload={"data": "test"},
            idempotency_key="key_1",
        )
        assert schema.action == "create"

    def test_valid_update_action(self):
        """Test valid update action."""
        schema = SyncItemSchema(
            entity_type="order",
            entity_id="local_order_1",
            action="update",
            payload={"data": "test"},
            idempotency_key="key_1",
        )
        assert schema.action == "update"

    def test_valid_delete_action(self):
        """Test valid delete action."""
        schema = SyncItemSchema(
            entity_type="order",
            entity_id="local_order_1",
            action="delete",
            payload={"data": "test"},
            idempotency_key="key_1",
        )
        assert schema.action == "delete"

    def test_invalid_action(self):
        """Test invalid action type."""
        with pytest.raises(ValidationError) as exc_info:
            SyncItemSchema(
                entity_type="order",
                entity_id="local_order_1",
                action="invalid_action",
                payload={"data": "test"},
                idempotency_key="key_1",
            )
        assert "create|update|delete" in str(exc_info.value)
