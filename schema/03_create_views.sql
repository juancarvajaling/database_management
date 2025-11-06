-- ============================================================================
-- View Creation Script
-- ============================================================================
-- Competency: Creates and modifies database objects
-- Competency: Combines multiple queries to optimise query execution
-- Description: Creates views to simplify complex queries and improve performance
-- ============================================================================

-- ============================================================================
-- CUSTOMER SUMMARY VIEW
-- ============================================================================
CREATE OR REPLACE VIEW v_customer_summary AS
SELECT 
    c.customer_id,
    c.email,
    c.first_name,
    c.last_name,
    c.customer_tier,
    c.created_at as member_since,
    COUNT(DISTINCT o.order_id) as total_orders,
    COALESCE(SUM(o.total_amount), 0) as lifetime_value,
    COALESCE(AVG(o.total_amount), 0) as avg_order_value,
    MAX(o.order_date) as last_order_date,
    COUNT(DISTINCT r.review_id) as review_count,
    COALESCE(AVG(r.rating), 0) as avg_rating_given
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id AND o.order_status != 'CANCELLED'
LEFT JOIN reviews r ON c.customer_id = r.customer_id
WHERE c.is_active = TRUE
GROUP BY c.customer_id, c.email, c.first_name, c.last_name, c.customer_tier, c.created_at;

COMMENT ON VIEW v_customer_summary IS 'Comprehensive customer analytics including order history and review activity';

-- ============================================================================
-- PRODUCT PERFORMANCE VIEW
-- ============================================================================
CREATE OR REPLACE VIEW v_product_performance AS
SELECT 
    p.product_id,
    p.product_name,
    p.sku,
    pc.category_name,
    p.unit_price,
    p.cost_price,
    p.unit_price - p.cost_price as profit_margin,
    ROUND(((p.unit_price - p.cost_price) / p.cost_price * 100), 2) as profit_margin_percent,
    COUNT(DISTINCT oi.order_id) as times_ordered,
    COALESCE(SUM(oi.quantity), 0) as total_units_sold,
    COALESCE(SUM(oi.line_total), 0) as total_revenue,
    COALESCE(AVG(r.rating), 0) as avg_rating,
    COUNT(DISTINCT r.review_id) as review_count,
    SUM(CASE WHEN i.quantity_available > 0 THEN i.quantity_available ELSE 0 END) as total_inventory,
    p.is_active
FROM products p
INNER JOIN product_categories pc ON p.category_id = pc.category_id
LEFT JOIN order_items oi ON p.product_id = oi.product_id
LEFT JOIN reviews r ON p.product_id = r.product_id
LEFT JOIN inventory i ON p.product_id = i.product_id
GROUP BY p.product_id, p.product_name, p.sku, pc.category_name, p.unit_price, p.cost_price, p.is_active;

COMMENT ON VIEW v_product_performance IS 'Product sales performance with profitability and inventory metrics';

-- ============================================================================
-- ORDER DETAILS VIEW
-- ============================================================================
CREATE OR REPLACE VIEW v_order_details AS
SELECT 
    o.order_id,
    o.order_date,
    o.order_status,
    o.payment_status,
    c.customer_id,
    c.email as customer_email,
    c.first_name || ' ' || c.last_name as customer_name,
    c.customer_tier,
    COUNT(oi.order_item_id) as item_count,
    SUM(oi.quantity) as total_items,
    o.subtotal,
    o.tax_amount,
    o.shipping_cost,
    o.discount_amount,
    o.total_amount,
    sa.street_address || ', ' || sa.city || ', ' || sa.state || ' ' || sa.postal_code as shipping_address,
    o.shipped_at,
    o.delivered_at,
    CASE 
        WHEN o.delivered_at IS NOT NULL THEN EXTRACT(DAY FROM o.delivered_at - o.order_date)
        ELSE NULL
    END as delivery_days
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
INNER JOIN addresses sa ON o.shipping_address_id = sa.address_id
LEFT JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY 
    o.order_id, o.order_date, o.order_status, o.payment_status,
    c.customer_id, c.email, c.first_name, c.last_name, c.customer_tier,
    o.subtotal, o.tax_amount, o.shipping_cost, o.discount_amount, o.total_amount,
    sa.street_address, sa.city, sa.state, sa.postal_code,
    o.shipped_at, o.delivered_at;

COMMENT ON VIEW v_order_details IS 'Comprehensive order information with customer and shipping details';

-- ============================================================================
-- DAILY SALES SUMMARY VIEW
-- ============================================================================
CREATE OR REPLACE VIEW v_daily_sales_summary AS
SELECT 
    DATE(order_date) as sale_date,
    COUNT(DISTINCT order_id) as order_count,
    COUNT(DISTINCT customer_id) as unique_customers,
    SUM(total_amount) as daily_revenue,
    AVG(total_amount) as avg_order_value,
    SUM(discount_amount) as total_discounts,
    SUM(tax_amount) as total_tax_collected,
    SUM(shipping_cost) as total_shipping_revenue
FROM orders
WHERE order_status NOT IN ('CANCELLED', 'REFUNDED')
GROUP BY DATE(order_date)
ORDER BY sale_date DESC;

COMMENT ON VIEW v_daily_sales_summary IS 'Daily sales metrics for reporting and trend analysis';

-- ============================================================================
-- INVENTORY STATUS VIEW
-- ============================================================================
CREATE OR REPLACE VIEW v_inventory_status AS
SELECT 
    i.inventory_id,
    p.product_id,
    p.product_name,
    p.sku,
    pc.category_name,
    i.warehouse_location,
    i.quantity_available,
    i.quantity_reserved,
    i.quantity_available - i.quantity_reserved as quantity_free,
    i.reorder_level,
    i.reorder_quantity,
    CASE 
        WHEN i.quantity_available = 0 THEN 'OUT_OF_STOCK'
        WHEN i.quantity_available <= i.reorder_level THEN 'LOW_STOCK'
        WHEN i.quantity_available > i.reorder_level * 3 THEN 'OVERSTOCKED'
        ELSE 'NORMAL'
    END as stock_status,
    i.last_restocked_at,
    EXTRACT(DAY FROM CURRENT_TIMESTAMP - i.last_restocked_at) as days_since_restock
FROM inventory i
INNER JOIN products p ON i.product_id = p.product_id
INNER JOIN product_categories pc ON p.category_id = pc.category_id
WHERE p.is_active = TRUE;

COMMENT ON VIEW v_inventory_status IS 'Current inventory status with stock level indicators';

-- ============================================================================
-- TOP CUSTOMERS VIEW
-- ============================================================================
CREATE OR REPLACE VIEW v_top_customers AS
SELECT 
    c.customer_id,
    c.email,
    c.first_name || ' ' || c.last_name as customer_name,
    c.customer_tier,
    COUNT(DISTINCT o.order_id) as order_count,
    SUM(o.total_amount) as total_spent,
    AVG(o.total_amount) as avg_order_value,
    MAX(o.order_date) as last_order_date,
    EXTRACT(DAY FROM CURRENT_TIMESTAMP - MAX(o.order_date)) as days_since_last_order,
    ROUND(SUM(o.total_amount) / NULLIF(COUNT(DISTINCT o.order_id), 0), 2) as customer_lifetime_value
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id
WHERE c.is_active = TRUE 
    AND o.order_status NOT IN ('CANCELLED', 'REFUNDED')
GROUP BY c.customer_id, c.email, c.first_name, c.last_name, c.customer_tier
HAVING COUNT(DISTINCT o.order_id) >= 3
ORDER BY total_spent DESC;

COMMENT ON VIEW v_top_customers IS 'High-value customers with purchase metrics';

-- ============================================================================
-- PRODUCT CATEGORY PERFORMANCE VIEW
-- ============================================================================
CREATE OR REPLACE VIEW v_category_performance AS
SELECT 
    pc.category_id,
    pc.category_name,
    COUNT(DISTINCT p.product_id) as product_count,
    COUNT(DISTINCT oi.order_id) as order_count,
    COALESCE(SUM(oi.quantity), 0) as units_sold,
    COALESCE(SUM(oi.line_total), 0) as total_revenue,
    COALESCE(AVG(oi.unit_price), 0) as avg_selling_price,
    COALESCE(AVG(r.rating), 0) as avg_category_rating
FROM product_categories pc
LEFT JOIN products p ON pc.category_id = p.category_id AND p.is_active = TRUE
LEFT JOIN order_items oi ON p.product_id = oi.product_id
LEFT JOIN reviews r ON p.product_id = r.product_id
GROUP BY pc.category_id, pc.category_name
ORDER BY total_revenue DESC;

COMMENT ON VIEW v_category_performance IS 'Sales performance aggregated by product category';

-- ============================================================================
-- MONTHLY REVENUE TREND VIEW
-- ============================================================================
CREATE OR REPLACE VIEW v_monthly_revenue_trend AS
SELECT 
    DATE_TRUNC('month', order_date) as month,
    COUNT(DISTINCT order_id) as order_count,
    COUNT(DISTINCT customer_id) as unique_customers,
    SUM(total_amount) as monthly_revenue,
    AVG(total_amount) as avg_order_value,
    SUM(discount_amount) as total_discounts_given,
    ROUND(SUM(discount_amount) / NULLIF(SUM(subtotal + discount_amount), 0) * 100, 2) as discount_percentage
FROM orders
WHERE order_status NOT IN ('CANCELLED', 'REFUNDED')
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY month DESC;

COMMENT ON VIEW v_monthly_revenue_trend IS 'Monthly revenue trends and discount analysis';

-- ============================================================================
-- ACTIVE PROMOTIONS VIEW
-- ============================================================================
CREATE OR REPLACE VIEW v_active_promotions AS
SELECT 
    promotion_id,
    promotion_code,
    description,
    discount_type,
    discount_value,
    min_purchase_amount,
    max_discount_amount,
    start_date,
    end_date,
    usage_limit,
    usage_count,
    CASE 
        WHEN usage_limit IS NOT NULL THEN usage_limit - usage_count
        ELSE NULL
    END as remaining_uses,
    EXTRACT(DAY FROM end_date - CURRENT_TIMESTAMP) as days_until_expiry
FROM promotions
WHERE is_active = TRUE
    AND CURRENT_TIMESTAMP BETWEEN start_date AND end_date
    AND (usage_limit IS NULL OR usage_count < usage_limit)
ORDER BY end_date ASC;

COMMENT ON VIEW v_active_promotions IS 'Currently active and available promotional codes';

-- ============================================================================
-- Display created views
-- ============================================================================
SELECT 
    schemaname,
    viewname,
    viewowner,
    definition
FROM pg_views
WHERE schemaname = 'public'
ORDER BY viewname;


