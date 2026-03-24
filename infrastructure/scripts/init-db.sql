-- ═══════════════════════════════════════════════════
-- Kheteebaadi - Database Initialization Script
-- Runs on first container creation
-- ═══════════════════════════════════════════════════

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";       -- Trigram index for fuzzy text search

-- ═══════════════════════════════════════════════════
-- TABLES
-- ═══════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS villages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    name_local VARCHAR(255),
    district VARCHAR(255) NOT NULL,
    state VARCHAR(255) NOT NULL,
    pin_code VARCHAR(10),
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone VARCHAR(15) NOT NULL UNIQUE,
    name VARCHAR(255),
    village_id UUID REFERENCES villages(id),
    language_pref VARCHAR(5) DEFAULT 'hi',
    avatar_url TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS mandis (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    name_local VARCHAR(255),
    district VARCHAR(255) NOT NULL,
    state VARCHAR(255) NOT NULL,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS mandi_prices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    mandi_id UUID NOT NULL REFERENCES mandis(id),
    crop_name VARCHAR(255) NOT NULL,
    crop_name_local VARCHAR(255),
    price_per_quintal NUMERIC(10,2) NOT NULL,
    min_price NUMERIC(10,2),
    max_price NUMERIC(10,2),
    unit VARCHAR(50) DEFAULT 'quintal',
    price_date DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id),
    order_number VARCHAR(20) NOT NULL UNIQUE,
    status VARCHAR(20) NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending','confirmed','processing','shipped','delivered','cancelled')),
    total_amount NUMERIC(12,2) NOT NULL DEFAULT 0,
    delivery_address TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS order_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    crop_name VARCHAR(255) NOT NULL,
    quantity NUMERIC(10,2) NOT NULL,
    unit VARCHAR(50) NOT NULL DEFAULT 'kg',
    price_per_unit NUMERIC(10,2) NOT NULL,
    subtotal NUMERIC(12,2) NOT NULL
);

CREATE TABLE IF NOT EXISTS sync_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id),
    idempotency_key VARCHAR(255) NOT NULL UNIQUE,
    entity_type VARCHAR(50) NOT NULL,
    entity_id VARCHAR(255),
    action VARCHAR(20) NOT NULL CHECK (action IN ('create','update','delete')),
    payload JSONB,
    status VARCHAR(20) NOT NULL DEFAULT 'processed'
        CHECK (status IN ('processed','failed','duplicate')),
    error_message TEXT,
    processed_at TIMESTAMPTZ DEFAULT NOW()
);

-- ═══════════════════════════════════════════════════
-- INDEXES
-- ═══════════════════════════════════════════════════

CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone);
CREATE INDEX IF NOT EXISTS idx_users_village ON users(village_id);
CREATE INDEX IF NOT EXISTS idx_mandi_prices_mandi_date ON mandi_prices(mandi_id, price_date DESC);
CREATE INDEX IF NOT EXISTS idx_mandi_prices_crop ON mandi_prices(crop_name);
CREATE INDEX IF NOT EXISTS idx_mandi_prices_crop_trgm ON mandi_prices USING gin(crop_name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_mandi_prices_crop_local_trgm ON mandi_prices USING gin(crop_name_local gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_orders_user ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_number ON orders(order_number);
CREATE INDEX IF NOT EXISTS idx_orders_created ON orders(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_sync_logs_user ON sync_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_sync_logs_idempotency ON sync_logs(idempotency_key);
CREATE INDEX IF NOT EXISTS idx_sync_logs_processed ON sync_logs(processed_at);
CREATE INDEX IF NOT EXISTS idx_villages_state_district ON villages(state, district);

-- ═══════════════════════════════════════════════════
-- SEED DATA: Sample Villages (Madhya Pradesh)
-- ═══════════════════════════════════════════════════

INSERT INTO villages (name, name_local, district, state, pin_code, latitude, longitude) VALUES
    ('Bhopal',       'भोपाल',      'Bhopal',    'Madhya Pradesh', '462001', 23.2599, 77.4126),
    ('Indore',       'इंदौर',       'Indore',    'Madhya Pradesh', '452001', 22.7196, 75.8577),
    ('Sehore',       'सीहोर',       'Sehore',    'Madhya Pradesh', '466001', 23.2000, 77.0833),
    ('Hoshangabad',  'होशंगाबाद',    'Hoshangabad','Madhya Pradesh','461001', 22.7500, 77.7333),
    ('Raisen',       'रायसेन',      'Raisen',    'Madhya Pradesh', '464551', 23.3300, 77.7800),
    ('Vidisha',      'विदिशा',      'Vidisha',   'Madhya Pradesh', '464001', 23.5300, 77.8100),
    ('Dewas',        'देवास',       'Dewas',     'Madhya Pradesh', '455001', 22.9600, 76.0500),
    ('Ujjain',       'उज्जैन',      'Ujjain',    'Madhya Pradesh', '456001', 23.1765, 75.7885),
    ('Gwalior',      'ग्वालियर',     'Gwalior',   'Madhya Pradesh', '474001', 26.2183, 78.1828),
    ('Jabalpur',     'जबलपुर',      'Jabalpur',  'Madhya Pradesh', '482001', 23.1815, 79.9864)
ON CONFLICT DO NOTHING;

-- ═══════════════════════════════════════════════════
-- SEED DATA: Sample Mandis
-- ═══════════════════════════════════════════════════

INSERT INTO mandis (name, name_local, district, state, latitude, longitude) VALUES
    ('Bhopal Mandi',     'भोपाल मंडी',     'Bhopal',   'Madhya Pradesh', 23.2650, 77.4100),
    ('Indore Mandi',     'इंदौर मंडी',      'Indore',   'Madhya Pradesh', 22.7250, 75.8600),
    ('Sehore Mandi',     'सीहोर मंडी',      'Sehore',   'Madhya Pradesh', 23.2050, 77.0850),
    ('Hoshangabad Mandi','होशंगाबाद मंडी',   'Hoshangabad','Madhya Pradesh',22.7550, 77.7350),
    ('Ujjain Mandi',     'उज्जैन मंडी',     'Ujjain',   'Madhya Pradesh', 23.1800, 75.7900)
ON CONFLICT DO NOTHING;

-- ═══════════════════════════════════════════════════
-- SEED DATA: Sample Mandi Prices
-- ═══════════════════════════════════════════════════

DO $$
DECLARE
    bhopal_id UUID;
    indore_id UUID;
    sehore_id UUID;
BEGIN
    SELECT id INTO bhopal_id FROM mandis WHERE name = 'Bhopal Mandi' LIMIT 1;
    SELECT id INTO indore_id FROM mandis WHERE name = 'Indore Mandi' LIMIT 1;
    SELECT id INTO sehore_id FROM mandis WHERE name = 'Sehore Mandi' LIMIT 1;

    IF bhopal_id IS NOT NULL THEN
        INSERT INTO mandi_prices (mandi_id, crop_name, crop_name_local, price_per_quintal, min_price, max_price, price_date) VALUES
            (bhopal_id, 'Wheat',    'गेहूं',    2275.00, 2200.00, 2350.00, CURRENT_DATE),
            (bhopal_id, 'Rice',     'चावल',    3150.00, 3050.00, 3250.00, CURRENT_DATE),
            (bhopal_id, 'Soybean',  'सोयाबीन',  4520.00, 4400.00, 4650.00, CURRENT_DATE),
            (bhopal_id, 'Gram',     'चना',      5100.00, 4950.00, 5200.00, CURRENT_DATE),
            (bhopal_id, 'Maize',    'मक्का',    1890.00, 1800.00, 1950.00, CURRENT_DATE),
            (bhopal_id, 'Mustard',  'सरसों',    5250.00, 5100.00, 5400.00, CURRENT_DATE),
            (bhopal_id, 'Onion',    'प्याज़',     1200.00, 1050.00, 1350.00, CURRENT_DATE),
            (bhopal_id, 'Potato',   'आलू',      850.00,  750.00,  950.00,  CURRENT_DATE);
    END IF;

    IF indore_id IS NOT NULL THEN
        INSERT INTO mandi_prices (mandi_id, crop_name, crop_name_local, price_per_quintal, min_price, max_price, price_date) VALUES
            (indore_id, 'Wheat',    'गेहूं',    2310.00, 2250.00, 2380.00, CURRENT_DATE),
            (indore_id, 'Soybean',  'सोयाबीन',  4600.00, 4500.00, 4700.00, CURRENT_DATE),
            (indore_id, 'Gram',     'चना',      5050.00, 4900.00, 5150.00, CURRENT_DATE),
            (indore_id, 'Cotton',   'कपास',    6800.00, 6650.00, 6950.00, CURRENT_DATE),
            (indore_id, 'Garlic',   'लहसुन',    8500.00, 8200.00, 8800.00, CURRENT_DATE);
    END IF;

    IF sehore_id IS NOT NULL THEN
        INSERT INTO mandi_prices (mandi_id, crop_name, crop_name_local, price_per_quintal, min_price, max_price, price_date) VALUES
            (sehore_id, 'Wheat',    'गेहूं',    2250.00, 2180.00, 2320.00, CURRENT_DATE),
            (sehore_id, 'Rice',     'चावल',    3100.00, 3000.00, 3200.00, CURRENT_DATE),
            (sehore_id, 'Lentil',   'मसूर दाल',  5600.00, 5450.00, 5750.00, CURRENT_DATE),
            (sehore_id, 'Soybean',  'सोयाबीन',  4480.00, 4350.00, 4600.00, CURRENT_DATE);
    END IF;
END $$;

-- ═══════════════════════════════════════════════════
-- FUNCTIONS
-- ═══════════════════════════════════════════════════

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_orders_updated_at
    BEFORE UPDATE ON orders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Haversine distance function (km) for nearby queries
CREATE OR REPLACE FUNCTION haversine_distance(
    lat1 DOUBLE PRECISION, lon1 DOUBLE PRECISION,
    lat2 DOUBLE PRECISION, lon2 DOUBLE PRECISION
) RETURNS DOUBLE PRECISION AS $$
DECLARE
    R DOUBLE PRECISION := 6371.0;
    dlat DOUBLE PRECISION;
    dlon DOUBLE PRECISION;
    a DOUBLE PRECISION;
    c DOUBLE PRECISION;
BEGIN
    dlat := RADIANS(lat2 - lat1);
    dlon := RADIANS(lon2 - lon1);
    a := SIN(dlat/2)^2 + COS(RADIANS(lat1)) * COS(RADIANS(lat2)) * SIN(dlon/2)^2;
    c := 2 * ASIN(SQRT(a));
    RETURN R * c;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

RAISE NOTICE 'Kheteebaadi database initialized successfully!';
