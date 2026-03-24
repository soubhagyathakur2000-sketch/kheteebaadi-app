-- Migration: 002_phase2_schema
-- Kheteebaadi Phase 2: Complete Database Schema
-- Includes: RBAC, OVOL Partners, Dual Catalogs, Unified Orders, i18n, Notifications

BEGIN;

-- Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
CREATE EXTENSION IF NOT EXISTS "btree_gin";

-- ═══════════════════════════════════════════════════
-- 1. IDENTITY & RBAC
-- ═══════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS regions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    name_local VARCHAR(255),
    state VARCHAR(255) NOT NULL,
    boundary GEOMETRY(POLYGON, 4326),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Drop and recreate villages to add region_id
ALTER TABLE villages ADD COLUMN IF NOT EXISTS region_id UUID REFERENCES regions(id);

CREATE TABLE IF NOT EXISTS roles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    slug VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    is_system BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS permissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    slug VARCHAR(100) UNIQUE NOT NULL,
    name VARCHAR(200) NOT NULL,
    module VARCHAR(50) NOT NULL,
    description TEXT
);

CREATE TABLE IF NOT EXISTS role_permissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    permission_id UUID NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
    UNIQUE(role_id, permission_id)
);

CREATE TABLE IF NOT EXISTS user_roles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    assigned_at TIMESTAMPTZ DEFAULT NOW(),
    assigned_by UUID REFERENCES users(id),
    UNIQUE(user_id, role_id)
);

-- ═══════════════════════════════════════════════════
-- 2. OVOL PARTNER NETWORK
-- ═══════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS ovol_partners (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID UNIQUE NOT NULL REFERENCES users(id),
    region_id UUID NOT NULL REFERENCES regions(id),
    partner_code VARCHAR(50) UNIQUE NOT NULL,
    status VARCHAR(20) DEFAULT 'pending'
        CHECK (status IN ('active', 'suspended', 'pending', 'terminated')),
    onboarded_at DATE,
    farmer_capacity INTEGER DEFAULT 100,
    commission_rate NUMERIC(5,2) DEFAULT 2.50,
    bank_details JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS ovol_farmer_assignments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ovol_partner_id UUID NOT NULL REFERENCES ovol_partners(id),
    farmer_user_id UUID NOT NULL REFERENCES users(id),
    status VARCHAR(20) DEFAULT 'active'
        CHECK (status IN ('active', 'released', 'transferred')),
    assigned_at DATE DEFAULT CURRENT_DATE,
    released_at DATE,
    notes TEXT,
    UNIQUE(ovol_partner_id, farmer_user_id, status)
);

CREATE TABLE IF NOT EXISTS ovol_activity_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ovol_partner_id UUID NOT NULL REFERENCES ovol_partners(id),
    action VARCHAR(50) NOT NULL,
    target_user_id UUID REFERENCES users(id),
    details JSONB DEFAULT '{}',
    performed_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS farmer_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID UNIQUE NOT NULL REFERENCES users(id),
    total_land_acres NUMERIC(10,2),
    land_ownership_type VARCHAR(50)
        CHECK (land_ownership_type IN ('owned', 'leased', 'shared', 'government')),
    crops_grown JSONB DEFAULT '[]',
    irrigation_type VARCHAR(100),
    has_tractor BOOLEAN DEFAULT FALSE,
    kcc_status VARCHAR(20) DEFAULT 'none'
        CHECK (kcc_status IN ('none', 'applied', 'approved', 'expired')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ═══════════════════════════════════════════════════
-- 3. MARKETPLACE CATALOG (Crops)
-- ═══════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS crop_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    name_local VARCHAR(255),
    slug VARCHAR(255) UNIQUE NOT NULL,
    parent_id UUID REFERENCES crop_categories(id),
    sort_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS crop_listings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farmer_id UUID NOT NULL REFERENCES users(id),
    category_id UUID NOT NULL REFERENCES crop_categories(id),
    crop_name VARCHAR(255) NOT NULL,
    crop_name_local VARCHAR(255),
    crop_variety VARCHAR(100),
    quantity_available NUMERIC(10,2) NOT NULL CHECK (quantity_available >= 0),
    quantity_unit VARCHAR(20) NOT NULL DEFAULT 'quintal',
    asking_price_per_unit NUMERIC(10,2) NOT NULL CHECK (asking_price_per_unit > 0),
    currency VARCHAR(10) DEFAULT 'INR',
    quality_grade VARCHAR(20) DEFAULT 'ungraded'
        CHECK (quality_grade IN ('A', 'B', 'C', 'ungraded')),
    expected_harvest_date DATE,
    listing_expiry_date DATE,
    status VARCHAR(20) DEFAULT 'draft'
        CHECK (status IN ('draft', 'active', 'sold', 'expired', 'suspended')),
    village_id UUID REFERENCES villages(id),
    description TEXT,
    dynamic_attributes JSONB DEFAULT '{}',
    is_organic BOOLEAN DEFAULT FALSE,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS crop_listing_images (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    crop_listing_id UUID NOT NULL REFERENCES crop_listings(id) ON DELETE CASCADE,
    image_url VARCHAR(512) NOT NULL,
    sort_order INTEGER DEFAULT 0,
    is_primary BOOLEAN DEFAULT FALSE,
    uploaded_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS crop_quality_inspections (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    crop_listing_id UUID NOT NULL REFERENCES crop_listings(id),
    inspector_id UUID NOT NULL REFERENCES users(id),
    grade_assigned VARCHAR(20) NOT NULL,
    moisture_pct NUMERIC(5,2),
    foreign_matter_pct NUMERIC(5,2),
    lab_results JSONB,
    remarks TEXT,
    inspected_at TIMESTAMPTZ DEFAULT NOW()
);

-- ═══════════════════════════════════════════════════
-- 4. AGROCHEMICAL STORE (Inputs)
-- ═══════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS agro_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    name_local VARCHAR(255),
    slug VARCHAR(255) UNIQUE NOT NULL,
    parent_id UUID REFERENCES agro_categories(id),
    category_type VARCHAR(50)
        CHECK (category_type IN ('seeds', 'fertilizers', 'pesticides', 'herbicides', 'equipment', 'other')),
    sort_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS suppliers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_name VARCHAR(255) NOT NULL,
    brand_name VARCHAR(255),
    contact_email VARCHAR(100),
    contact_phone VARCHAR(15),
    address TEXT,
    gst_number VARCHAR(50),
    status VARCHAR(20) DEFAULT 'active'
        CHECK (status IN ('active', 'inactive', 'blacklisted')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS agro_products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    category_id UUID NOT NULL REFERENCES agro_categories(id),
    supplier_id UUID NOT NULL REFERENCES suppliers(id),
    sku VARCHAR(50) UNIQUE NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    product_name_local VARCHAR(255),
    description TEXT,
    mrp NUMERIC(10,2) NOT NULL CHECK (mrp > 0),
    selling_price NUMERIC(10,2) NOT NULL CHECK (selling_price > 0),
    unit_of_measure VARCHAR(20) NOT NULL,
    weight_kg NUMERIC(10,3),
    image_url VARCHAR(512),
    specifications JSONB DEFAULT '{}',
    is_active BOOLEAN DEFAULT TRUE,
    hsn_code VARCHAR(50),
    gst_rate NUMERIC(5,2) DEFAULT 18.00,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CHECK (selling_price <= mrp)
);

CREATE TABLE IF NOT EXISTS warehouses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    region_id UUID REFERENCES regions(id),
    address TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    is_active BOOLEAN DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS inventory (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id UUID NOT NULL REFERENCES agro_products(id),
    warehouse_id UUID NOT NULL REFERENCES warehouses(id),
    quantity_on_hand INTEGER NOT NULL DEFAULT 0 CHECK (quantity_on_hand >= 0),
    quantity_reserved INTEGER DEFAULT 0 CHECK (quantity_reserved >= 0),
    reorder_level INTEGER DEFAULT 10,
    reorder_quantity INTEGER DEFAULT 50,
    last_restock_date DATE,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(product_id, warehouse_id),
    CHECK (quantity_reserved <= quantity_on_hand)
);

-- ═══════════════════════════════════════════════════
-- 5. UNIFIED ORDER SYSTEM (extends Phase 1)
-- ═══════════════════════════════════════════════════

-- Drop old orders if they exist from Phase 1, recreate with expanded schema
-- (In production, use ALTER TABLE instead)

DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;

CREATE TABLE orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_number VARCHAR(20) UNIQUE NOT NULL,
    buyer_id UUID NOT NULL REFERENCES users(id),
    seller_id UUID REFERENCES users(id),
    order_type VARCHAR(20) NOT NULL
        CHECK (order_type IN ('crop_purchase', 'agro_purchase')),
    status VARCHAR(20) DEFAULT 'pending'
        CHECK (status IN ('pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled', 'refunded')),
    subtotal NUMERIC(12,2) NOT NULL CHECK (subtotal >= 0),
    delivery_fee NUMERIC(10,2) DEFAULT 0,
    tax_amount NUMERIC(10,2) DEFAULT 0,
    total_amount NUMERIC(12,2) NOT NULL CHECK (total_amount >= 0),
    currency VARCHAR(10) DEFAULT 'INR',
    delivery_address TEXT,
    delivery_village_id UUID REFERENCES villages(id),
    notes TEXT,
    idempotency_key VARCHAR(36) UNIQUE,
    placed_at TIMESTAMPTZ,
    confirmed_at TIMESTAMPTZ,
    shipped_at TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,
    cancelled_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE order_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    item_type VARCHAR(20) NOT NULL
        CHECK (item_type IN ('crop', 'agro_product')),
    crop_listing_id UUID REFERENCES crop_listings(id),
    agro_product_id UUID REFERENCES agro_products(id),
    item_name VARCHAR(255) NOT NULL,
    quantity NUMERIC(10,2) NOT NULL CHECK (quantity > 0),
    unit VARCHAR(20) NOT NULL,
    price_per_unit NUMERIC(10,2) NOT NULL CHECK (price_per_unit >= 0),
    subtotal NUMERIC(12,2) NOT NULL CHECK (subtotal >= 0),
    tax_rate NUMERIC(5,2) DEFAULT 0,
    tax_amount NUMERIC(10,2) DEFAULT 0,
    -- Ensure exactly one catalog reference is set
    CHECK (
        (item_type = 'crop' AND crop_listing_id IS NOT NULL AND agro_product_id IS NULL)
        OR
        (item_type = 'agro_product' AND agro_product_id IS NOT NULL AND crop_listing_id IS NULL)
    )
);

CREATE TABLE IF NOT EXISTS order_status_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    from_status VARCHAR(20),
    to_status VARCHAR(20) NOT NULL,
    changed_by UUID REFERENCES users(id),
    reason TEXT,
    changed_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES orders(id),
    payment_gateway VARCHAR(50) NOT NULL,
    gateway_txn_id VARCHAR(100),
    amount NUMERIC(12,2) NOT NULL CHECK (amount > 0),
    currency VARCHAR(10) DEFAULT 'INR',
    status VARCHAR(20) DEFAULT 'initiated'
        CHECK (status IN ('initiated', 'processing', 'success', 'failed', 'refunded')),
    method VARCHAR(20)
        CHECK (method IN ('upi', 'card', 'netbanking', 'cod', 'wallet')),
    gateway_response JSONB,
    initiated_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

-- ═══════════════════════════════════════════════════
-- 6. LOCALIZATION (i18n)
-- ═══════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS locales (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code VARCHAR(10) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    native_name VARCHAR(100) NOT NULL,
    direction VARCHAR(5) DEFAULT 'ltr',
    is_active BOOLEAN DEFAULT TRUE,
    sort_order INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS translation_namespaces (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    namespace VARCHAR(100) UNIQUE NOT NULL,
    description TEXT
);

CREATE TABLE IF NOT EXISTS translation_keys (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    namespace_id UUID NOT NULL REFERENCES translation_namespaces(id) ON DELETE CASCADE,
    key VARCHAR(255) NOT NULL,
    default_text TEXT NOT NULL,
    context_hint VARCHAR(200),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(namespace_id, key)
);

CREATE TABLE IF NOT EXISTS translations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    key_id UUID NOT NULL REFERENCES translation_keys(id) ON DELETE CASCADE,
    locale_id UUID NOT NULL REFERENCES locales(id) ON DELETE CASCADE,
    translated_text TEXT NOT NULL,
    is_verified BOOLEAN DEFAULT FALSE,
    verified_by UUID REFERENCES users(id),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(key_id, locale_id)
);

CREATE TABLE IF NOT EXISTS translation_versions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    translation_id UUID NOT NULL REFERENCES translations(id) ON DELETE CASCADE,
    previous_text TEXT,
    new_text TEXT NOT NULL,
    changed_by UUID REFERENCES users(id),
    changed_at TIMESTAMPTZ DEFAULT NOW()
);

-- ═══════════════════════════════════════════════════
-- 7. NOTIFICATIONS
-- ═══════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    channel VARCHAR(50) NOT NULL
        CHECK (channel IN ('push', 'sms', 'in_app')),
    title VARCHAR(255),
    body TEXT,
    data JSONB DEFAULT '{}',
    is_read BOOLEAN DEFAULT FALSE,
    sent_at TIMESTAMPTZ DEFAULT NOW(),
    read_at TIMESTAMPTZ
);

-- ═══════════════════════════════════════════════════
-- 8. PERFORMANCE INDEXES
-- ═══════════════════════════════════════════════════

-- i18n Fast Path
CREATE INDEX idx_translations_locale_key ON translations(locale_id, key_id);
CREATE INDEX idx_translation_keys_ns_key ON translation_keys(namespace_id, key);

-- JSONB GIN indexes
CREATE INDEX idx_crop_listings_dynamic_attrs ON crop_listings USING GIN(dynamic_attributes jsonb_path_ops);
CREATE INDEX idx_agro_products_specs ON agro_products USING GIN(specifications jsonb_path_ops);
CREATE INDEX idx_farmer_profiles_crops ON farmer_profiles USING GIN(crops_grown jsonb_path_ops);

-- Partial indexes for active records
CREATE INDEX idx_active_crop_listings ON crop_listings(village_id, category_id, asking_price_per_unit)
    WHERE status = 'active';
CREATE INDEX idx_active_agro_products ON agro_products(category_id, selling_price)
    WHERE is_active = TRUE;
CREATE INDEX idx_active_ovol_assignments ON ovol_farmer_assignments(ovol_partner_id, farmer_user_id)
    WHERE status = 'active';

-- BRIN for time-series
CREATE INDEX idx_orders_created_brin ON orders USING BRIN(created_at) WITH (pages_per_range = 32);
CREATE INDEX idx_ovol_activity_brin ON ovol_activity_logs USING BRIN(performed_at) WITH (pages_per_range = 32);
CREATE INDEX idx_notifications_sent_brin ON notifications USING BRIN(sent_at) WITH (pages_per_range = 32);

-- Trigram for fuzzy search
CREATE INDEX idx_crop_name_trgm ON crop_listings USING GIN(crop_name gin_trgm_ops);
CREATE INDEX idx_crop_name_local_trgm ON crop_listings USING GIN(crop_name_local gin_trgm_ops);
CREATE INDEX idx_agro_product_name_trgm ON agro_products USING GIN(product_name gin_trgm_ops);
CREATE INDEX idx_agro_product_name_local_trgm ON agro_products USING GIN(product_name_local gin_trgm_ops);

-- Core query indexes
CREATE INDEX idx_orders_buyer ON orders(buyer_id, status);
CREATE INDEX idx_orders_seller ON orders(seller_id, status);
CREATE INDEX idx_orders_type_status ON orders(order_type, status);
CREATE INDEX idx_order_items_order ON order_items(order_id);
CREATE INDEX idx_crop_listings_farmer ON crop_listings(farmer_id, status);
CREATE INDEX idx_inventory_product ON inventory(product_id, warehouse_id);
CREATE INDEX idx_payments_order ON payments(order_id);
CREATE INDEX idx_notifications_user_unread ON notifications(user_id) WHERE is_read = FALSE;
CREATE INDEX idx_ovol_partners_region ON ovol_partners(region_id) WHERE status = 'active';
CREATE INDEX idx_villages_region ON villages(region_id);

-- ═══════════════════════════════════════════════════
-- 9. TRIGGERS
-- ═══════════════════════════════════════════════════

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
    tbl TEXT;
BEGIN
    FOR tbl IN SELECT unnest(ARRAY[
        'ovol_partners', 'farmer_profiles', 'crop_listings',
        'agro_products', 'inventory', 'orders'
    ]) LOOP
        EXECUTE format(
            'DROP TRIGGER IF EXISTS trg_%s_updated_at ON %I;
             CREATE TRIGGER trg_%s_updated_at BEFORE UPDATE ON %I
             FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();',
            tbl, tbl, tbl, tbl
        );
    END LOOP;
END $$;

-- Order number generator
CREATE OR REPLACE FUNCTION generate_order_number()
RETURNS TRIGGER AS $$
DECLARE
    prefix TEXT;
    seq_val BIGINT;
BEGIN
    IF NEW.order_type = 'crop_purchase' THEN
        prefix := 'KM';
    ELSE
        prefix := 'KS';
    END IF;
    seq_val := nextval('order_number_seq');
    NEW.order_number := prefix || TO_CHAR(NOW(), 'YYMMDD') || LPAD(seq_val::TEXT, 5, '0');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE SEQUENCE IF NOT EXISTS order_number_seq START 1;

CREATE TRIGGER trg_order_number
    BEFORE INSERT ON orders
    FOR EACH ROW
    WHEN (NEW.order_number IS NULL)
    EXECUTE FUNCTION generate_order_number();

-- Order status history auto-log
CREATE OR REPLACE FUNCTION log_order_status_change()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        INSERT INTO order_status_history (order_id, from_status, to_status, changed_at)
        VALUES (NEW.id, OLD.status, NEW.status, NOW());
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_order_status_history
    AFTER UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION log_order_status_change();

-- Translation version tracking
CREATE OR REPLACE FUNCTION log_translation_version()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.translated_text IS DISTINCT FROM NEW.translated_text THEN
        INSERT INTO translation_versions (translation_id, previous_text, new_text, changed_at)
        VALUES (NEW.id, OLD.translated_text, NEW.translated_text, NOW());
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_translation_version
    AFTER UPDATE ON translations
    FOR EACH ROW
    EXECUTE FUNCTION log_translation_version();

-- ═══════════════════════════════════════════════════
-- 10. MATERIALIZED VIEW: OVOL Dashboard
-- ═══════════════════════════════════════════════════

CREATE MATERIALIZED VIEW IF NOT EXISTS mv_ovol_dashboard AS
SELECT
    op.id AS ovol_partner_id,
    op.partner_code,
    op.region_id,
    u.name AS ovol_name,
    u.phone AS ovol_phone,
    COUNT(DISTINCT ofa.farmer_user_id) FILTER (WHERE ofa.status = 'active') AS active_farmers,
    COUNT(DISTINCT o.id) FILTER (WHERE o.created_at >= DATE_TRUNC('month', NOW())) AS orders_this_month,
    COALESCE(SUM(o.total_amount) FILTER (WHERE o.status = 'delivered' AND o.created_at >= DATE_TRUNC('month', NOW())), 0) AS revenue_this_month,
    COALESCE(SUM(o.total_amount * op.commission_rate / 100) FILTER (WHERE o.status = 'delivered' AND o.created_at >= DATE_TRUNC('month', NOW())), 0) AS commission_this_month,
    COUNT(DISTINCT cl.id) FILTER (WHERE cl.status = 'active') AS active_listings
FROM ovol_partners op
JOIN users u ON op.user_id = u.id
LEFT JOIN ovol_farmer_assignments ofa ON op.id = ofa.ovol_partner_id
LEFT JOIN orders o ON o.buyer_id = ofa.farmer_user_id OR o.seller_id = ofa.farmer_user_id
LEFT JOIN crop_listings cl ON cl.farmer_id = ofa.farmer_user_id
WHERE op.status = 'active'
GROUP BY op.id, op.partner_code, op.region_id, op.commission_rate, u.name, u.phone;

CREATE UNIQUE INDEX idx_mv_ovol_dashboard_id ON mv_ovol_dashboard(ovol_partner_id);

-- ═══════════════════════════════════════════════════
-- 11. SEED DATA
-- ═══════════════════════════════════════════════════

-- Roles
INSERT INTO roles (slug, name, description, is_system) VALUES
    ('farmer',         'Farmer',           'Agricultural producer who lists crops',                    TRUE),
    ('buyer',          'Buyer',            'Purchases crops from marketplace or agro inputs from store', TRUE),
    ('ovol_lead',      'OVOL Lead',        'Village-level partner managing farmers in a region',        TRUE),
    ('ovol_admin',     'OVOL Admin',       'Senior OVOL with oversight across multiple leads',          TRUE),
    ('platform_admin', 'Platform Admin',   'Full system access',                                        TRUE)
ON CONFLICT (slug) DO NOTHING;

-- Permissions
INSERT INTO permissions (slug, name, module) VALUES
    ('marketplace.list.create',    'Create Crop Listing',        'marketplace'),
    ('marketplace.list.edit_own',  'Edit Own Listings',          'marketplace'),
    ('marketplace.list.view_all',  'View All Listings',          'marketplace'),
    ('marketplace.list.moderate',  'Moderate Listings',          'marketplace'),
    ('store.product.view',         'View Store Products',        'store'),
    ('store.product.manage',       'Manage Store Products',      'store'),
    ('store.inventory.manage',     'Manage Inventory',           'store'),
    ('orders.create',              'Create Orders',              'orders'),
    ('orders.view_own',            'View Own Orders',            'orders'),
    ('orders.view_region',         'View Regional Orders',       'orders'),
    ('orders.view_all',            'View All Orders',            'orders'),
    ('orders.manage_status',       'Update Order Status',        'orders'),
    ('users.view_own',             'View Own Profile',           'users'),
    ('users.edit_own',             'Edit Own Profile',           'users'),
    ('users.view_region',          'View Regional Users',        'users'),
    ('users.manage_all',           'Manage All Users',           'users'),
    ('ovol.view_dashboard',        'View OVOL Dashboard',        'ovol'),
    ('ovol.manage_farmers',        'Manage Farmer Assignments',  'ovol'),
    ('ovol.manage_leads',          'Manage OVOL Leads',          'ovol'),
    ('analytics.view_basic',       'View Basic Analytics',       'analytics'),
    ('analytics.view_full',        'View Full Analytics',        'analytics'),
    ('i18n.view',                  'View Translations',          'i18n'),
    ('i18n.manage',                'Manage Translations',        'i18n')
ON CONFLICT (slug) DO NOTHING;

-- Role-Permission mappings
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE (r.slug = 'farmer' AND p.slug IN (
    'marketplace.list.create', 'marketplace.list.edit_own', 'marketplace.list.view_all',
    'store.product.view', 'orders.create', 'orders.view_own',
    'users.view_own', 'users.edit_own', 'analytics.view_basic'
))
OR (r.slug = 'buyer' AND p.slug IN (
    'marketplace.list.view_all', 'store.product.view',
    'orders.create', 'orders.view_own',
    'users.view_own', 'users.edit_own', 'analytics.view_basic'
))
OR (r.slug = 'ovol_lead' AND p.slug IN (
    'marketplace.list.view_all', 'marketplace.list.moderate',
    'store.product.view', 'orders.view_region', 'orders.manage_status',
    'users.view_region', 'users.view_own', 'users.edit_own',
    'ovol.view_dashboard', 'ovol.manage_farmers', 'analytics.view_basic'
))
OR (r.slug = 'ovol_admin' AND p.slug IN (
    'marketplace.list.view_all', 'marketplace.list.moderate',
    'store.product.view', 'store.product.manage',
    'orders.view_all', 'orders.manage_status',
    'users.view_region', 'users.view_own', 'users.edit_own',
    'ovol.view_dashboard', 'ovol.manage_farmers', 'ovol.manage_leads',
    'analytics.view_full'
))
OR (r.slug = 'platform_admin' AND TRUE)
ON CONFLICT DO NOTHING;

-- Locales
INSERT INTO locales (code, name, native_name, direction, is_active, sort_order) VALUES
    ('en', 'English',   'English',   'ltr', TRUE,  1),
    ('hi', 'Hindi',     'हिन्दी',     'ltr', TRUE,  2),
    ('mr', 'Marathi',   'मराठी',     'ltr', TRUE,  3),
    ('pa', 'Punjabi',   'ਪੰਜਾਬੀ',    'ltr', TRUE,  4),
    ('ta', 'Tamil',     'தமிழ்',     'ltr', TRUE,  5),
    ('te', 'Telugu',    'తెలుగు',    'ltr', TRUE,  6),
    ('kn', 'Kannada',   'ಕನ್ನಡ',     'ltr', TRUE,  7),
    ('gu', 'Gujarati',  'ગુજરાતી',   'ltr', TRUE,  8),
    ('bn', 'Bengali',   'বাংলা',     'ltr', TRUE,  9),
    ('or', 'Odia',      'ଓଡ଼ିଆ',     'ltr', TRUE, 10)
ON CONFLICT (code) DO NOTHING;

-- Translation Namespaces
INSERT INTO translation_namespaces (namespace, description) VALUES
    ('common',   'Shared UI elements: buttons, labels, navigation'),
    ('auth',     'Login, OTP, registration screens'),
    ('mandi',    'Marketplace and crop listing screens'),
    ('store',    'Agrochemical store screens'),
    ('orders',   'Order management screens'),
    ('profile',  'User profile and settings'),
    ('ovol',     'OVOL partner dashboard'),
    ('errors',   'Error messages and validation'),
    ('notif',    'Notification titles and bodies')
ON CONFLICT (namespace) DO NOTHING;

-- Sample Translation Keys (common namespace)
DO $$
DECLARE
    ns_id UUID;
    en_id UUID;
    hi_id UUID;
    mr_id UUID;
    key_id_var UUID;
BEGIN
    SELECT id INTO ns_id FROM translation_namespaces WHERE namespace = 'common';
    SELECT id INTO en_id FROM locales WHERE code = 'en';
    SELECT id INTO hi_id FROM locales WHERE code = 'hi';
    SELECT id INTO mr_id FROM locales WHERE code = 'mr';

    -- app.name
    INSERT INTO translation_keys (namespace_id, key, default_text, context_hint) VALUES (ns_id, 'app.name', 'Kheteebaadi', 'App title') RETURNING id INTO key_id_var;
    INSERT INTO translations (key_id, locale_id, translated_text, is_verified) VALUES (key_id_var, en_id, 'Kheteebaadi', TRUE), (key_id_var, hi_id, 'खेतीबाड़ी', TRUE), (key_id_var, mr_id, 'खेतीवाडी', TRUE) ON CONFLICT DO NOTHING;

    -- btn.save
    INSERT INTO translation_keys (namespace_id, key, default_text, context_hint) VALUES (ns_id, 'btn.save', 'Save', 'Save button') RETURNING id INTO key_id_var;
    INSERT INTO translations (key_id, locale_id, translated_text, is_verified) VALUES (key_id_var, en_id, 'Save', TRUE), (key_id_var, hi_id, 'सहेजें', TRUE), (key_id_var, mr_id, 'जतन करा', TRUE) ON CONFLICT DO NOTHING;

    -- btn.cancel
    INSERT INTO translation_keys (namespace_id, key, default_text, context_hint) VALUES (ns_id, 'btn.cancel', 'Cancel', 'Cancel button') RETURNING id INTO key_id_var;
    INSERT INTO translations (key_id, locale_id, translated_text, is_verified) VALUES (key_id_var, en_id, 'Cancel', TRUE), (key_id_var, hi_id, 'रद्द करें', TRUE), (key_id_var, mr_id, 'रद्द करा', TRUE) ON CONFLICT DO NOTHING;

    -- nav.home
    INSERT INTO translation_keys (namespace_id, key, default_text, context_hint) VALUES (ns_id, 'nav.home', 'Home', 'Bottom nav') RETURNING id INTO key_id_var;
    INSERT INTO translations (key_id, locale_id, translated_text, is_verified) VALUES (key_id_var, en_id, 'Home', TRUE), (key_id_var, hi_id, 'होम', TRUE), (key_id_var, mr_id, 'मुख्यपृष्ठ', TRUE) ON CONFLICT DO NOTHING;

    -- nav.mandi
    INSERT INTO translation_keys (namespace_id, key, default_text, context_hint) VALUES (ns_id, 'nav.mandi', 'Mandi', 'Bottom nav - marketplace') RETURNING id INTO key_id_var;
    INSERT INTO translations (key_id, locale_id, translated_text, is_verified) VALUES (key_id_var, en_id, 'Mandi', TRUE), (key_id_var, hi_id, 'मंडी', TRUE), (key_id_var, mr_id, 'बाजार', TRUE) ON CONFLICT DO NOTHING;

    -- nav.orders
    INSERT INTO translation_keys (namespace_id, key, default_text, context_hint) VALUES (ns_id, 'nav.orders', 'Orders', 'Bottom nav') RETURNING id INTO key_id_var;
    INSERT INTO translations (key_id, locale_id, translated_text, is_verified) VALUES (key_id_var, en_id, 'Orders', TRUE), (key_id_var, hi_id, 'ऑर्डर', TRUE), (key_id_var, mr_id, 'ऑर्डर', TRUE) ON CONFLICT DO NOTHING;

    -- nav.profile
    INSERT INTO translation_keys (namespace_id, key, default_text, context_hint) VALUES (ns_id, 'nav.profile', 'Profile', 'Bottom nav') RETURNING id INTO key_id_var;
    INSERT INTO translations (key_id, locale_id, translated_text, is_verified) VALUES (key_id_var, en_id, 'Profile', TRUE), (key_id_var, hi_id, 'प्रोफ़ाइल', TRUE), (key_id_var, mr_id, 'प्रोफाइल', TRUE) ON CONFLICT DO NOTHING;

    -- status.offline
    INSERT INTO translation_keys (namespace_id, key, default_text, context_hint) VALUES (ns_id, 'status.offline', 'You are offline', 'Offline banner') RETURNING id INTO key_id_var;
    INSERT INTO translations (key_id, locale_id, translated_text, is_verified) VALUES (key_id_var, en_id, 'You are offline', TRUE), (key_id_var, hi_id, 'आप ऑफ़लाइन हैं', TRUE), (key_id_var, mr_id, 'तुम्ही ऑफलाइन आहात', TRUE) ON CONFLICT DO NOTHING;

    -- status.syncing
    INSERT INTO translation_keys (namespace_id, key, default_text, context_hint) VALUES (ns_id, 'status.syncing', 'Syncing data...', 'Sync indicator') RETURNING id INTO key_id_var;
    INSERT INTO translations (key_id, locale_id, translated_text, is_verified) VALUES (key_id_var, en_id, 'Syncing data...', TRUE), (key_id_var, hi_id, 'डेटा सिंक हो रहा है...', TRUE), (key_id_var, mr_id, 'डेटा सिंक होत आहे...', TRUE) ON CONFLICT DO NOTHING;

END $$;

-- Crop Categories
INSERT INTO crop_categories (name, name_local, slug, sort_order) VALUES
    ('Cereals',     'अनाज',       'cereals',     1),
    ('Pulses',      'दालें',       'pulses',      2),
    ('Oilseeds',    'तिलहन',      'oilseeds',    3),
    ('Vegetables',  'सब्जियां',     'vegetables',  4),
    ('Fruits',      'फल',         'fruits',      5),
    ('Spices',      'मसाले',       'spices',      6),
    ('Cash Crops',  'नकदी फसलें',   'cash-crops',  7),
    ('Fibers',      'रेशे',        'fibers',      8)
ON CONFLICT (slug) DO NOTHING;

-- Agro Categories
INSERT INTO agro_categories (name, name_local, slug, category_type, sort_order) VALUES
    ('Seeds',             'बीज',          'seeds',        'seeds',       1),
    ('Fertilizers',       'उर्वरक',       'fertilizers',  'fertilizers', 2),
    ('Pesticides',        'कीटनाशक',     'pesticides',   'pesticides',  3),
    ('Herbicides',        'शाकनाशी',     'herbicides',   'herbicides',  4),
    ('Farm Equipment',    'कृषि उपकरण',   'equipment',    'equipment',   5),
    ('Organic Inputs',    'जैविक उत्पाद',  'organic',      'other',       6)
ON CONFLICT (slug) DO NOTHING;

-- Regions
INSERT INTO regions (name, name_local, state) VALUES
    ('Central MP',      'मध्य म.प्र.',     'Madhya Pradesh'),
    ('Western MP',      'पश्चिमी म.प्र.',   'Madhya Pradesh'),
    ('Eastern MP',      'पूर्वी म.प्र.',    'Madhya Pradesh'),
    ('Northern MP',     'उत्तरी म.प्र.',    'Madhya Pradesh'),
    ('Malwa Plateau',   'मालवा पठार',     'Madhya Pradesh')
ON CONFLICT DO NOTHING;

COMMIT;
