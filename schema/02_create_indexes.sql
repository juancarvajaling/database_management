-- ============================================================================
-- Index Creation Script
-- ============================================================================
-- Competency: Applies technics for database optimisation
-- Competency: Creates and modifies database objects
-- Description: Creates indexes to optimize query performance
-- ============================================================================

-- ============================================================================
-- CUSTOMERS TABLE INDEXES
-- ============================================================================

-- Index for email lookups (frequently used for login)
CREATE INDEX idx_customers_email ON customers(email);

-- Index for customer tier filtering
CREATE INDEX idx_customers_tier ON customers(customer_tier) WHERE is_active = TRUE;

-- Index for active customers
CREATE INDEX idx_customers_active ON customers(is_active);

-- Composite index for customer search
CREATE INDEX idx_customers_name ON customers(last_name, first_name);

COMMENT ON INDEX idx_customers_email IS 'Optimizes customer lookup by email';
COMMENT ON INDEX idx_customers_tier IS 'Partial index for active customers by tier';

-- ============================================================================
-- ADDRESSES TABLE INDEXES
-- ============================================================================

-- Index for finding all addresses for a customer
CREATE INDEX idx_addresses_customer ON addresses(customer_id);

-- Composite index for address type queries
CREATE INDEX idx_addresses_customer_type ON addresses(customer_id, address_type);

-- Index for default address lookup
CREATE INDEX idx_addresses_default ON addresses(customer_id, is_default) WHERE is_default = TRUE;

-- ============================================================================
-- PRODUCTS TABLE INDEXES
-- ============================================================================

-- Index for category-based product searches
CREATE INDEX idx_products_category ON products(category_id) WHERE is_active = TRUE;

-- Index for SKU lookups
CREATE INDEX idx_products_sku ON products(sku);

-- Index for price range queries
CREATE INDEX idx_products_price ON products(unit_price);

-- Full-text search index for product names and descriptions
CREATE INDEX idx_products_search ON products USING gin(to_tsvector('english', product_name || ' ' || COALESCE(description, '')));

-- Composite index for active products by category
CREATE INDEX idx_products_active_category ON products(category_id, is_active, unit_price);

COMMENT ON INDEX idx_products_search IS 'Full-text search index for product discovery';

-- ============================================================================
-- INVENTORY TABLE INDEXES
-- ============================================================================

-- Index for product inventory lookups
CREATE INDEX idx_inventory_product ON inventory(product_id);

-- Index for warehouse location queries
CREATE INDEX idx_inventory_warehouse ON inventory(warehouse_location);

-- Index for low stock alerts
CREATE INDEX idx_inventory_low_stock ON inventory(product_id, warehouse_location) 
    WHERE quantity_available <= reorder_level;

-- Composite index for inventory availability checks
CREATE INDEX idx_inventory_availability ON inventory(product_id, warehouse_location, quantity_available);

COMMENT ON INDEX idx_inventory_low_stock IS 'Partial index for identifying products needing restock';

-- ============================================================================
-- ORDERS TABLE INDEXES
-- ============================================================================

-- Index for customer order history
CREATE INDEX idx_orders_customer ON orders(customer_id, order_date DESC);

-- Index for order status queries
CREATE INDEX idx_orders_status ON orders(order_status, order_date);

-- Index for payment status tracking
CREATE INDEX idx_orders_payment ON orders(payment_status);

-- Index for date range queries (reporting)
CREATE INDEX idx_orders_date ON orders(order_date DESC);

-- Composite index for order fulfillment queries
CREATE INDEX idx_orders_fulfillment ON orders(order_status, shipped_at, delivered_at);

-- Index for recent orders
CREATE INDEX idx_orders_recent ON orders(created_at DESC) WHERE order_status != 'CANCELLED';

COMMENT ON INDEX idx_orders_customer IS 'Optimizes customer order history queries';
COMMENT ON INDEX idx_orders_recent IS 'Partial index for active recent orders';

-- ============================================================================
-- ORDER ITEMS TABLE INDEXES
-- ============================================================================

-- Index for order details lookup
CREATE INDEX idx_order_items_order ON order_items(order_id);

-- Index for product sales analysis
CREATE INDEX idx_order_items_product ON order_items(product_id);

-- Composite index for sales reporting
CREATE INDEX idx_order_items_product_price ON order_items(product_id, unit_price, quantity);

-- ============================================================================
-- REVIEWS TABLE INDEXES
-- ============================================================================

-- Index for product reviews
CREATE INDEX idx_reviews_product ON reviews(product_id, created_at DESC);

-- Index for customer reviews
CREATE INDEX idx_reviews_customer ON reviews(customer_id);

-- Index for rating-based queries
CREATE INDEX idx_reviews_rating ON reviews(rating, created_at DESC);

-- Index for verified purchase reviews
CREATE INDEX idx_reviews_verified ON reviews(product_id, is_verified_purchase) 
    WHERE is_verified_purchase = TRUE;

-- Index for helpful reviews
CREATE INDEX idx_reviews_helpful ON reviews(helpful_count DESC) WHERE helpful_count > 0;

-- ============================================================================
-- PROMOTIONS TABLE INDEXES
-- ============================================================================

-- Index for promotion code lookups
CREATE INDEX idx_promotions_code ON promotions(promotion_code);

-- Index for active promotions in date range
CREATE INDEX idx_promotions_active ON promotions(start_date, end_date) 
    WHERE is_active = TRUE;

-- Index for promotion expiry monitoring
CREATE INDEX idx_promotions_expiry ON promotions(end_date) 
    WHERE is_active = TRUE AND end_date > CURRENT_TIMESTAMP;

-- ============================================================================
-- PRODUCT CATEGORIES TABLE INDEXES
-- ============================================================================

-- Index for hierarchical category queries
CREATE INDEX idx_categories_parent ON product_categories(parent_category_id);

-- Index for category name lookups
CREATE INDEX idx_categories_name ON product_categories(category_name);

-- ============================================================================
-- AUDIT LOG TABLE INDEXES
-- ============================================================================

-- Index for audit queries by table
CREATE INDEX idx_audit_table ON audit_log(table_name, changed_at DESC);

-- Index for tracking specific record changes
CREATE INDEX idx_audit_record ON audit_log(table_name, record_id, changed_at DESC);

-- Index for recent changes
CREATE INDEX idx_audit_recent ON audit_log(changed_at DESC);

-- JSONB indexes for searching audit data
CREATE INDEX idx_audit_new_values ON audit_log USING gin(new_values);
CREATE INDEX idx_audit_old_values ON audit_log USING gin(old_values);

-- ============================================================================
-- Display all indexes with their sizes
-- ============================================================================
SELECT
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

-- ============================================================================
-- Show index usage statistics (run after some queries)
-- ============================================================================
COMMENT ON INDEX idx_orders_date IS 'Run: SELECT * FROM pg_stat_user_indexes WHERE schemaname = ''public'' to view index usage statistics';


