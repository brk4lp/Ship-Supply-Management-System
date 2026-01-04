-- SSMS Database Initialization Script

-- Ships Table
CREATE TABLE IF NOT EXISTS ships (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    imo_number VARCHAR(20) UNIQUE NOT NULL,
    flag VARCHAR(100) NOT NULL,
    ship_type VARCHAR(100) NOT NULL,
    gross_tonnage DOUBLE PRECISION,
    owner VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Suppliers Table
CREATE TABLE IF NOT EXISTS suppliers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    contact_person VARCHAR(255),
    email VARCHAR(255),
    phone VARCHAR(50),
    address TEXT,
    country VARCHAR(100),
    category VARCHAR(100) NOT NULL,
    rating REAL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Supply Items Table
CREATE TABLE IF NOT EXISTS supply_items (
    id SERIAL PRIMARY KEY,
    supplier_id INTEGER NOT NULL REFERENCES suppliers(id) ON DELETE CASCADE,
    impa_code VARCHAR(50),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(100) NOT NULL,
    unit VARCHAR(50) NOT NULL,
    unit_price DECIMAL(15, 4) NOT NULL,
    currency VARCHAR(10) NOT NULL DEFAULT 'USD',
    minimum_order_quantity INTEGER,
    lead_time_days INTEGER,
    is_available BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Orders Table
CREATE TABLE IF NOT EXISTS orders (
    id SERIAL PRIMARY KEY,
    order_number VARCHAR(50) UNIQUE NOT NULL,
    ship_id INTEGER NOT NULL REFERENCES ships(id),
    supplier_id INTEGER NOT NULL REFERENCES suppliers(id),
    status VARCHAR(20) NOT NULL DEFAULT 'NEW',
    total_amount DECIMAL(15, 4) NOT NULL DEFAULT 0,
    currency VARCHAR(10) NOT NULL DEFAULT 'USD',
    delivery_port VARCHAR(255),
    delivery_date DATE,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    CONSTRAINT valid_status CHECK (status IN (
        'NEW', 'QUOTED', 'AGREED', 'WAITING_GOODS', 
        'PREPARED', 'ON_WAY', 'DELIVERED', 'INVOICED', 'CANCELLED'
    ))
);

-- Order Items Table (Critical for profit calculation)
CREATE TABLE IF NOT EXISTS order_items (
    id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_name VARCHAR(255) NOT NULL,
    impa_code VARCHAR(50),
    description TEXT,
    quantity DECIMAL(15, 4) NOT NULL,
    unit VARCHAR(50) NOT NULL,
    buying_price DECIMAL(15, 4) NOT NULL,  -- Cost (what we pay)
    selling_price DECIMAL(15, 4) NOT NULL, -- Revenue (what customer pays)
    currency VARCHAR(10) NOT NULL DEFAULT 'USD',
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for better performance
CREATE INDEX IF NOT EXISTS idx_orders_ship_id ON orders(ship_id);
CREATE INDEX IF NOT EXISTS idx_orders_supplier_id ON orders(supplier_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at);
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_supply_items_supplier_id ON supply_items(supplier_id);
CREATE INDEX IF NOT EXISTS idx_ships_imo_number ON ships(imo_number);

-- Updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply trigger to all tables
DO $$
DECLARE
    t text;
BEGIN
    FOR t IN 
        SELECT table_name FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_type = 'BASE TABLE'
        AND table_name IN ('ships', 'suppliers', 'supply_items', 'orders', 'order_items')
    LOOP
        EXECUTE format('
            DROP TRIGGER IF EXISTS update_%I_updated_at ON %I;
            CREATE TRIGGER update_%I_updated_at
            BEFORE UPDATE ON %I
            FOR EACH ROW
            EXECUTE FUNCTION update_updated_at_column();
        ', t, t, t, t);
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Sample data for development
INSERT INTO ships (name, imo_number, flag, ship_type, gross_tonnage, owner) VALUES
    ('M/V PACIFIC DREAM', '9876543', 'Panama', 'Bulk Carrier', 45000, 'Pacific Shipping Co.'),
    ('M/V MEDITERRANEAN STAR', '9123456', 'Malta', 'Container Ship', 65000, 'Star Lines Ltd.'),
    ('M/V ATLANTIC VOYAGER', '9234567', 'Liberia', 'Tanker', 80000, 'Atlantic Marine Inc.')
ON CONFLICT (imo_number) DO NOTHING;

INSERT INTO suppliers (name, contact_person, email, phone, country, category) VALUES
    ('Fresh Fruits Ltd.', 'John Smith', 'john@freshfruits.com', '+90 212 555 1234', 'Turkey', 'Provisions'),
    ('Marine Supplies Co.', 'Maria Garcia', 'maria@marinesupplies.com', '+90 216 555 5678', 'Turkey', 'Deck Supplies'),
    ('Technical Parts GmbH', 'Hans Mueller', 'hans@techparts.de', '+49 40 555 9012', 'Germany', 'Technical')
ON CONFLICT DO NOTHING;
