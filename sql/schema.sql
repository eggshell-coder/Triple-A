-- ============================================================
-- Triple A – Online Clothing Buy Website
-- Database Schema v2 — Matches backend controllers
-- Run in Supabase SQL Editor
-- ============================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- ADMINS
-- ============================================================
CREATE TABLE IF NOT EXISTS admins (
    id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    full_name  VARCHAR(255) NOT NULL,
    email      VARCHAR(255) UNIQUE NOT NULL,
    role       VARCHAR(50)  DEFAULT 'admin' CHECK (role IN ('admin', 'super_admin')),
    created_at TIMESTAMPTZ  DEFAULT NOW()
);

-- ============================================================
-- USERS  (mirrors Supabase auth.users for customer profile data)
-- ============================================================
CREATE TABLE IF NOT EXISTS users (
    id         UUID PRIMARY KEY,  -- same UUID as auth.users
    email      VARCHAR(255) UNIQUE NOT NULL,
    full_name  VARCHAR(255),
    phone      VARCHAR(30),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- CATEGORIES  (used for legacy/dashboard low-stock grouping)
-- ============================================================
CREATE TABLE IF NOT EXISTS categories (
    id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name       VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- COLLECTIONS  (primary product grouping — replaces categories)
-- ============================================================
CREATE TABLE IF NOT EXISTS collections (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name          VARCHAR(255) NOT NULL,
    slug          VARCHAR(255) UNIQUE NOT NULL,
    description   TEXT,
    image         TEXT,          -- cover image URL
    is_active     BOOLEAN    DEFAULT TRUE,
    display_order INTEGER    DEFAULT 0,
    created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- PRODUCTS
-- ============================================================
CREATE TABLE IF NOT EXISTS products (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    collection_id UUID REFERENCES collections(id) ON DELETE SET NULL,
    name          VARCHAR(255)   NOT NULL,
    description   TEXT,
    gender        VARCHAR(10)    CHECK (gender IN ('men', 'women')),
    type          VARCHAR(50)    CHECK (type IN (
                      'oversized','polo','full-sleeve',
                      'half-sleeve','drop-shoulder','basic'
                  )),
    price         NUMERIC(10, 2) NOT NULL CHECK (price >= 0),
    image         TEXT,          -- product image URL  (alias: image_url for older code)
    image_url     TEXT           GENERATED ALWAYS AS (image) STORED,
    stock         INTEGER        NOT NULL DEFAULT 0 CHECK (stock >= 0),
    is_active     BOOLEAN        DEFAULT TRUE,
    created_at    TIMESTAMPTZ    DEFAULT NOW(),
    updated_at    TIMESTAMPTZ    DEFAULT NOW()
);

CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER products_updated_at
    BEFORE UPDATE ON products
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================================
-- CUSTOMERS  (shipping info per order — not the same as users)
-- ============================================================
CREATE TABLE IF NOT EXISTS customers (
    id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    full_name    VARCHAR(255) NOT NULL,
    phone        VARCHAR(30)  NOT NULL,
    district     VARCHAR(100),
    upazila      VARCHAR(100),
    address_line TEXT,
    email        VARCHAR(255),
    created_at   TIMESTAMPTZ  DEFAULT NOW()
);

-- ============================================================
-- ORDERS
-- ============================================================
CREATE TABLE IF NOT EXISTS orders (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id     UUID           REFERENCES customers(id) ON DELETE SET NULL,
    user_id         UUID,          -- nullable: auth.users id if logged in
    total_amount    NUMERIC(10, 2) NOT NULL CHECK (total_amount >= 0),
    delivery_charge NUMERIC(10, 2) DEFAULT 0,
    district        VARCHAR(100),  -- denormalised for quick filter
    upazila         VARCHAR(100),
    status          VARCHAR(50)    DEFAULT 'pending'
                        CHECK (status IN ('pending','processing','confirmed',
                                          'shipped','delivered','completed','cancelled')),
    note            TEXT,
    created_at      TIMESTAMPTZ    DEFAULT NOW(),
    updated_at      TIMESTAMPTZ    DEFAULT NOW()
);

CREATE TRIGGER orders_updated_at
    BEFORE UPDATE ON orders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================================
-- ORDER ITEMS
-- ============================================================
CREATE TABLE IF NOT EXISTS order_items (
    id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id   UUID           NOT NULL REFERENCES orders(id)   ON DELETE CASCADE,
    product_id UUID           NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    quantity   INTEGER        NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC(10, 2) NOT NULL
);

-- ============================================================
-- WISHLISTS
-- ============================================================
CREATE TABLE IF NOT EXISTS wishlists (
    id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id    UUID        NOT NULL,  -- auth.users id
    product_id UUID        NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (user_id, product_id)
);

-- ============================================================
-- INDEXES
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_products_collection  ON products(collection_id);
CREATE INDEX IF NOT EXISTS idx_products_gender       ON products(gender);
CREATE INDEX IF NOT EXISTS idx_products_type         ON products(type);
CREATE INDEX IF NOT EXISTS idx_products_is_active    ON products(is_active);
CREATE INDEX IF NOT EXISTS idx_orders_customer       ON orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_user           ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_status         ON orders(status);
CREATE INDEX IF NOT EXISTS idx_order_items_order     ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_wishlists_user        ON wishlists(user_id);
CREATE INDEX IF NOT EXISTS idx_wishlists_product     ON wishlists(product_id);

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================
ALTER TABLE products    ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders      ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers   ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE wishlists   ENABLE ROW LEVEL SECURITY;
ALTER TABLE users       ENABLE ROW LEVEL SECURITY;
ALTER TABLE collections ENABLE ROW LEVEL SECURITY;

-- Public can read active products and collections
CREATE POLICY "Public read active products"
    ON products FOR SELECT USING (is_active = TRUE);

CREATE POLICY "Public read active collections"
    ON collections FOR SELECT USING (is_active = TRUE);

-- Service role (backend service key) bypasses RLS — no extra policies needed.

-- ============================================================
-- STORAGE BUCKET
-- ============================================================
-- Run in Supabase Dashboard → Storage:
-- 1. Create bucket: "product-images"  (public: true)
-- 2. Or via SQL:
-- INSERT INTO storage.buckets (id, name, public)
--   VALUES ('product-images', 'product-images', true)
--   ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- SAMPLE DATA
-- ============================================================
INSERT INTO collections (name, slug, description, display_order) VALUES
    ('Summer Essentials', 'summer-essentials', 'Light and breezy tees for the warm season', 1),
    ('Street Culture',    'street-culture',    'Bold oversized fits for the streets',        2),
    ('Classic Polos',     'classic-polos',     'Refined polo shirts for every occasion',     3)
ON CONFLICT (slug) DO NOTHING;

INSERT INTO categories (name) VALUES
    ('T-Shirts'), ('Polo Shirts'), ('Graphic Tees'), ('Oversized'), ('Limited Edition')
ON CONFLICT (name) DO NOTHING;

INSERT INTO products (name, gender, type, price, stock, description, image, is_active)
VALUES
    ('Classic White Heritage Tee',  'men',   'basic',        890,  50, 'Premium 100% cotton T-shirt.',
     'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=800', TRUE),
    ('Forest Green Essential',      'men',   'basic',        950,  35, 'Soft-washed jersey in forest green.',
     'https://images.unsplash.com/photo-1618354691373-d851c5c3a990?w=800', TRUE),
    ('Urban Typography Tee',        'men',   'oversized',   1200,  20, 'Bold graphic oversized tee.',
     'https://images.unsplash.com/photo-1583743814966-8936f5b7be1a?w=800', TRUE),
    ('Heritage Polo Classic',       'men',   'polo',        1450,  25, 'Refined pique cotton polo.',
     'https://images.unsplash.com/photo-1586363104862-3a5e2ab60d99?w=800', TRUE),
    ('Drop Shoulder Oversized',     'men',   'drop-shoulder',1100, 40, 'Contemporary boxy silhouette.',
     'https://images.unsplash.com/photo-1576566588028-4147f3842f27?w=800', TRUE),
    ('Floral Embroidered Tee',      'women', 'basic',       1800,  10, 'Hand-embroidered floral motif.',
     'https://images.unsplash.com/photo-1503341504253-dff4815485f1?w=800', TRUE)
ON CONFLICT DO NOTHING;
