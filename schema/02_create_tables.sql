-- ============================================================================
-- Table Creation Script
-- ============================================================================
-- Competency: Creates and modifies database objects
-- Competency: Implements and modifies database structure
-- Description: Creates normalized tables with proper constraints and relationships
-- ============================================================================

-- Set search path
SET search_path TO public;

-- ============================================================================
-- CUSTOMERS TABLE
-- ============================================================================
CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    date_of_birth DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    customer_tier VARCHAR(20) DEFAULT 'BRONZE' CHECK (customer_tier IN ('BRONZE', 'SILVER', 'GOLD', 'PLATINUM')),
    CONSTRAINT valid_email CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT valid_dob CHECK (date_of_birth < CURRENT_DATE)
);

COMMENT ON TABLE customers IS 'Stores customer information with tier-based classification';
COMMENT ON COLUMN customers.customer_tier IS 'Customer loyalty tier: BRONZE, SILVER, GOLD, or PLATINUM';

-- ============================================================================
-- ADDRESSES TABLE
-- ============================================================================
CREATE TABLE addresses (
    address_id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL,
    address_type VARCHAR(20) NOT NULL CHECK (address_type IN ('BILLING', 'SHIPPING')),
    street_address VARCHAR(255) NOT NULL,
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100),
    postal_code VARCHAR(20) NOT NULL,
    country VARCHAR(100) NOT NULL DEFAULT 'USA',
    is_default BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE CASCADE
);

COMMENT ON TABLE addresses IS 'Customer addresses for billing and shipping';

-- ============================================================================
-- PRODUCT CATEGORIES TABLE
-- ============================================================================
CREATE TABLE product_categories (
    category_id SERIAL PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL UNIQUE,
    parent_category_id INTEGER,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (parent_category_id) REFERENCES product_categories(category_id) ON DELETE SET NULL
);

COMMENT ON TABLE product_categories IS 'Hierarchical product category structure';

-- ============================================================================
-- PRODUCTS TABLE
-- ============================================================================
CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(255) NOT NULL,
    category_id INTEGER NOT NULL,
    sku VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    unit_price DECIMAL(10, 2) NOT NULL CHECK (unit_price >= 0),
    cost_price DECIMAL(10, 2) NOT NULL CHECK (cost_price >= 0),
    weight_kg DECIMAL(8, 2),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES product_categories(category_id),
    CONSTRAINT valid_pricing CHECK (unit_price >= cost_price)
);

COMMENT ON TABLE products IS 'Product catalog with pricing and category information';

-- ============================================================================
-- INVENTORY TABLE
-- ============================================================================
CREATE TABLE inventory (
    inventory_id SERIAL PRIMARY KEY,
    product_id INTEGER NOT NULL,
    warehouse_location VARCHAR(100) NOT NULL,
    quantity_available INTEGER NOT NULL DEFAULT 0 CHECK (quantity_available >= 0),
    quantity_reserved INTEGER NOT NULL DEFAULT 0 CHECK (quantity_reserved >= 0),
    reorder_level INTEGER NOT NULL DEFAULT 10,
    reorder_quantity INTEGER NOT NULL DEFAULT 50,
    last_restocked_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    CONSTRAINT valid_quantities CHECK (quantity_reserved <= quantity_available),
    UNIQUE (product_id, warehouse_location)
);

COMMENT ON TABLE inventory IS 'Product inventory tracking across warehouse locations';

-- ============================================================================
-- ORDERS TABLE
-- ============================================================================
CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    shipping_address_id INTEGER NOT NULL,
    billing_address_id INTEGER NOT NULL,
    order_status VARCHAR(20) NOT NULL DEFAULT 'PENDING' 
        CHECK (order_status IN ('PENDING', 'CONFIRMED', 'PROCESSING', 'SHIPPED', 'DELIVERED', 'CANCELLED', 'REFUNDED')),
    payment_status VARCHAR(20) NOT NULL DEFAULT 'PENDING'
        CHECK (payment_status IN ('PENDING', 'COMPLETED', 'FAILED', 'REFUNDED')),
    payment_method VARCHAR(50),
    subtotal DECIMAL(10, 2) NOT NULL CHECK (subtotal >= 0),
    tax_amount DECIMAL(10, 2) NOT NULL DEFAULT 0 CHECK (tax_amount >= 0),
    shipping_cost DECIMAL(10, 2) NOT NULL DEFAULT 0 CHECK (shipping_cost >= 0),
    discount_amount DECIMAL(10, 2) NOT NULL DEFAULT 0 CHECK (discount_amount >= 0),
    total_amount DECIMAL(10, 2) NOT NULL CHECK (total_amount >= 0),
    shipped_at TIMESTAMP,
    delivered_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (shipping_address_id) REFERENCES addresses(address_id),
    FOREIGN KEY (billing_address_id) REFERENCES addresses(address_id),
    CONSTRAINT valid_total CHECK (total_amount = subtotal + tax_amount + shipping_cost - discount_amount)
);

COMMENT ON TABLE orders IS 'Customer orders with status tracking and financial information';

-- ============================================================================
-- ORDER ITEMS TABLE
-- ============================================================================
CREATE TABLE order_items (
    order_item_id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(10, 2) NOT NULL CHECK (unit_price >= 0),
    discount_percent DECIMAL(5, 2) DEFAULT 0 CHECK (discount_percent >= 0 AND discount_percent <= 100),
    line_total DECIMAL(10, 2) NOT NULL CHECK (line_total >= 0),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    CONSTRAINT valid_line_total CHECK (line_total = ROUND(quantity * unit_price * (1 - discount_percent / 100), 2))
);

COMMENT ON TABLE order_items IS 'Individual items within each order with pricing details';

-- ============================================================================
-- REVIEWS TABLE
-- ============================================================================
CREATE TABLE reviews (
    review_id SERIAL PRIMARY KEY,
    product_id INTEGER NOT NULL,
    customer_id INTEGER NOT NULL,
    order_id INTEGER NOT NULL,
    rating INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
    review_title VARCHAR(200),
    review_text TEXT,
    is_verified_purchase BOOLEAN DEFAULT TRUE,
    helpful_count INTEGER DEFAULT 0 CHECK (helpful_count >= 0),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    UNIQUE (product_id, customer_id, order_id)
);

COMMENT ON TABLE reviews IS 'Customer product reviews and ratings';

-- ============================================================================
-- PROMOTIONS TABLE
-- ============================================================================
CREATE TABLE promotions (
    promotion_id SERIAL PRIMARY KEY,
    promotion_code VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    discount_type VARCHAR(20) NOT NULL CHECK (discount_type IN ('PERCENTAGE', 'FIXED_AMOUNT')),
    discount_value DECIMAL(10, 2) NOT NULL CHECK (discount_value > 0),
    min_purchase_amount DECIMAL(10, 2) DEFAULT 0,
    max_discount_amount DECIMAL(10, 2),
    start_date TIMESTAMP NOT NULL,
    end_date TIMESTAMP NOT NULL,
    usage_limit INTEGER,
    usage_count INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_dates CHECK (end_date > start_date),
    CONSTRAINT valid_usage CHECK (usage_count <= usage_limit OR usage_limit IS NULL)
);

COMMENT ON TABLE promotions IS 'Promotional codes and discount campaigns';

-- ============================================================================
-- ORDER PROMOTIONS TABLE (Many-to-Many relationship)
-- ============================================================================
CREATE TABLE order_promotions (
    order_id INTEGER NOT NULL,
    promotion_id INTEGER NOT NULL,
    discount_applied DECIMAL(10, 2) NOT NULL,
    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (order_id, promotion_id),
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
    FOREIGN KEY (promotion_id) REFERENCES promotions(promotion_id)
);

COMMENT ON TABLE order_promotions IS 'Links orders to applied promotional discounts';

-- ============================================================================
-- AUDIT LOG TABLE
-- ============================================================================
CREATE TABLE audit_log (
    audit_id SERIAL PRIMARY KEY,
    table_name VARCHAR(100) NOT NULL,
    record_id INTEGER NOT NULL,
    action VARCHAR(20) NOT NULL CHECK (action IN ('INSERT', 'UPDATE', 'DELETE')),
    old_values JSONB,
    new_values JSONB,
    changed_by VARCHAR(100),
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE audit_log IS 'Audit trail for tracking changes to critical tables';

-- ============================================================================
-- Display created tables
-- ============================================================================
SELECT 
    schemaname,
    tablename,
    tableowner
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;


