"""Initial migration - create all tables.

Revision ID: 001_initial
Create Date: 2024-01-01 00:00:00.000000
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = "001_initial"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    """Create initial schema."""
    # Create villages table
    op.create_table(
        "villages",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("name", sa.String(255), nullable=False),
        sa.Column("name_local", sa.String(255), nullable=True),
        sa.Column("district", sa.String(255), nullable=False),
        sa.Column("state", sa.String(255), nullable=False),
        sa.Column("latitude", sa.Float(), nullable=False),
        sa.Column("longitude", sa.Float(), nullable=False),
        sa.Column("pin_code", sa.String(10), nullable=False),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default="true"),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("idx_village_coords", "villages", ["latitude", "longitude"])
    op.create_index("idx_village_district", "villages", ["district"])
    op.create_index("idx_village_state", "villages", ["state"])

    # Create users table
    op.create_table(
        "users",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("phone", sa.String(20), nullable=False),
        sa.Column("name", sa.String(255), nullable=True),
        sa.Column("village_id", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("language_pref", sa.String(10), nullable=False, server_default="hi"),
        sa.Column("avatar_url", sa.String(500), nullable=True),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default="true"),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
        sa.ForeignKeyConstraint(["village_id"], ["villages.id"]),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("phone"),
    )
    op.create_index("idx_user_created", "users", ["created_at"])
    op.create_index("idx_user_phone", "users", ["phone"])
    op.create_index("idx_user_village", "users", ["village_id"])

    # Create mandis table
    op.create_table(
        "mandis",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("name", sa.String(255), nullable=False),
        sa.Column("name_local", sa.String(255), nullable=True),
        sa.Column("district", sa.String(255), nullable=False),
        sa.Column("state", sa.String(255), nullable=False),
        sa.Column("latitude", sa.Float(), nullable=False),
        sa.Column("longitude", sa.Float(), nullable=False),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default="true"),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("idx_mandi_coords", "mandis", ["latitude", "longitude"])
    op.create_index("idx_mandi_district", "mandis", ["district"])
    op.create_index("idx_mandi_state", "mandis", ["state"])

    # Create mandi_prices table
    op.create_table(
        "mandi_prices",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("mandi_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("crop_name", sa.String(255), nullable=False),
        sa.Column("crop_name_local", sa.String(255), nullable=True),
        sa.Column("price_per_quintal", sa.Numeric(10, 2), nullable=False),
        sa.Column("unit", sa.String(50), nullable=False, server_default="quintal"),
        sa.Column("price_date", sa.Date(), nullable=False),
        sa.Column("min_price", sa.Numeric(10, 2), nullable=True),
        sa.Column("max_price", sa.Numeric(10, 2), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
        sa.ForeignKeyConstraint(["mandi_id"], ["mandis.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("idx_mandi_price_crop", "mandi_prices", ["crop_name"])
    op.create_index("idx_mandi_price_date", "mandi_prices", ["price_date"])
    op.create_index(
        "idx_mandi_price_mandi",
        "mandi_prices",
        ["mandi_id"],
    )
    op.create_index(
        "idx_mandi_price_mandi_crop_date",
        "mandi_prices",
        ["mandi_id", "crop_name", "price_date"],
    )

    # Create orders table
    op.create_table(
        "orders",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("order_number", sa.String(50), nullable=False),
        sa.Column(
            "status",
            sa.Enum(
                "pending",
                "confirmed",
                "processing",
                "shipped",
                "delivered",
                "cancelled",
                name="orderstatus",
            ),
            nullable=False,
            server_default="pending",
        ),
        sa.Column("total_amount", sa.Numeric(12, 2), nullable=False),
        sa.Column("delivery_address", sa.Text(), nullable=False),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"]),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("order_number"),
    )
    op.create_index("idx_order_created", "orders", ["created_at"])
    op.create_index("idx_order_status", "orders", ["status"])
    op.create_index("idx_order_user", "orders", ["user_id"])

    # Create order_items table
    op.create_table(
        "order_items",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("order_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("crop_name", sa.String(255), nullable=False),
        sa.Column("quantity", sa.Numeric(10, 2), nullable=False),
        sa.Column("unit", sa.String(50), nullable=False),
        sa.Column("price_per_unit", sa.Numeric(10, 2), nullable=False),
        sa.Column("subtotal", sa.Numeric(12, 2), nullable=False),
        sa.ForeignKeyConstraint(["order_id"], ["orders.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("idx_order_item_order", "order_items", ["order_id"])

    # Create sync_logs table
    op.create_table(
        "sync_logs",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("idempotency_key", sa.String(255), nullable=False),
        sa.Column("entity_type", sa.String(100), nullable=False),
        sa.Column("entity_id", sa.String(255), nullable=False),
        sa.Column("action", sa.String(50), nullable=False),
        sa.Column("payload", postgresql.JSON(), nullable=False),
        sa.Column(
            "status",
            sa.Enum("processed", "failed", "duplicate", name="syncstatus"),
            nullable=False,
            server_default="processed",
        ),
        sa.Column("error_message", sa.Text(), nullable=True),
        sa.Column(
            "processed_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"]),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("idempotency_key"),
    )
    op.create_index("idx_sync_entity", "sync_logs", ["entity_type", "entity_id"])
    op.create_index("idx_sync_idempotency", "sync_logs", ["idempotency_key"])
    op.create_index("idx_sync_processed", "sync_logs", ["processed_at"])
    op.create_index("idx_sync_status", "sync_logs", ["status"])
    op.create_index("idx_sync_user", "sync_logs", ["user_id"])


def downgrade() -> None:
    """Drop all tables."""
    op.drop_index("idx_sync_user", table_name="sync_logs")
    op.drop_index("idx_sync_status", table_name="sync_logs")
    op.drop_index("idx_sync_processed", table_name="sync_logs")
    op.drop_index("idx_sync_idempotency", table_name="sync_logs")
    op.drop_index("idx_sync_entity", table_name="sync_logs")
    op.drop_table("sync_logs")

    op.drop_index("idx_order_item_order", table_name="order_items")
    op.drop_table("order_items")

    op.drop_index("idx_order_created", table_name="orders")
    op.drop_index("idx_order_status", table_name="orders")
    op.drop_index("idx_order_user", table_name="orders")
    op.drop_table("orders")

    op.drop_index("idx_mandi_price_mandi_crop_date", table_name="mandi_prices")
    op.drop_index("idx_mandi_price_mandi", table_name="mandi_prices")
    op.drop_index("idx_mandi_price_date", table_name="mandi_prices")
    op.drop_index("idx_mandi_price_crop", table_name="mandi_prices")
    op.drop_table("mandi_prices")

    op.drop_index("idx_mandi_state", table_name="mandis")
    op.drop_index("idx_mandi_district", table_name="mandis")
    op.drop_index("idx_mandi_coords", table_name="mandis")
    op.drop_table("mandis")

    op.drop_index("idx_user_village", table_name="users")
    op.drop_index("idx_user_phone", table_name="users")
    op.drop_index("idx_user_created", table_name="users")
    op.drop_table("users")

    op.drop_index("idx_village_state", table_name="villages")
    op.drop_index("idx_village_district", table_name="villages")
    op.drop_index("idx_village_coords", table_name="villages")
    op.drop_table("villages")
