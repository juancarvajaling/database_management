-- ============================================================================
-- Materialized Views for Performance Optimization
-- ============================================================================
-- Competency: Applies technics for database optimisation
-- Description: Demonstrates materialized views for caching complex query results
-- ============================================================================

-- ============================================================================
-- 1. Basic Materialized View
-- ============================================================================
-- Pre-compute expensive customer analytics
CREATE MATERIALIZED VIEW mv_customer_analytics AS
SELECT 
    c.customer_id,
    c.email,
    c.first_name || ' ' || c.last_name as customer_name,
    c.customer_tier,
    c.created_at as member_since,
    COUNT(DISTINCT o.order_id) as total_orders,
    COALESCE(SUM(o.total_amount), 0) as lifetime_value,
    COALESCE(AVG(o.total_amount), 0) as avg_order_value,
    MAX(o.order_date) as last_order_date,
    EXTRACT(DAY FROM CURRENT_TIMESTAMP - MAX(o.order_date)) as days_since_last_order,
    COUNT(DISTINCT r.review_id) as reviews_written,
    COALESCE(AVG(r.rating), 0) as avg_rating_given,
    MIN(o.order_date) as first_order_date,
    EXTRACT(DAY FROM CURRENT_TIMESTAMP - MIN(o.order_date)) as customer_lifetime_days
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id AND o.order_status NOT IN ('CANCELLED', 'REFUNDED')
LEFT JOIN reviews r ON c.customer_id = r.customer_id
WHERE c.is_active = TRUE
GROUP BY c.customer_id, c.email, c.first_name, c.last_name, c.customer_tier, c.created_at;

-- Create index on materialized view for fast lookups
CREATE INDEX idx_mv_customer_tier ON mv_customer_analytics(customer_tier);
CREATE INDEX idx_mv_customer_lifetime ON mv_customer_analytics(lifetime_value DESC);
CREATE INDEX idx_mv_customer_last_order ON mv_customer_analytics(last_order_date DESC);

COMMENT ON MATERIALIZED VIEW mv_customer_analytics IS 'Pre-computed customer metrics refreshed daily';

-- ============================================================================
-- 2. Refresh Materialized View
-- ============================================================================
-- Full refresh (blocks reads during refresh)
-- REFRESH MATERIALIZED VIEW mv_customer_analytics;

-- Concurrent refresh (allows reads during refresh, requires unique index)
CREATE UNIQUE INDEX idx_mv_customer_pk ON mv_customer_analytics(customer_id);
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_customer_analytics;

-- ============================================================================
-- 3. Product Performance Materialized View
-- ============================================================================
CREATE MATERIALIZED VIEW mv_product_performance AS
SELECT 
    p.product_id,
    p.product_name,
    p.sku,
    pc.category_name,
    p.unit_price,
    p.cost_price,
    p.unit_price - p.cost_price as profit_per_unit,
    ROUND(((p.unit_price - p.cost_price) / NULLIF(p.cost_price, 0) * 100), 2) as profit_margin_percent,
    COUNT(DISTINCT oi.order_id) as times_ordered,
    COALESCE(SUM(oi.quantity), 0) as total_units_sold,
    COALESCE(SUM(oi.line_total), 0) as total_revenue,
    COALESCE(SUM(oi.line_total) - (SUM(oi.quantity) * p.cost_price), 0) as total_profit,
    COALESCE(AVG(r.rating), 0) as avg_rating,
    COUNT(DISTINCT r.review_id) as review_count,
    COALESCE(SUM(i.quantity_available), 0) as total_inventory,
    p.is_active,
    CURRENT_TIMESTAMP as last_refreshed
FROM products p
INNER JOIN product_categories pc ON p.category_id = pc.category_id
LEFT JOIN order_items oi ON p.product_id = oi.product_id
LEFT JOIN reviews r ON p.product_id = r.product_id
LEFT JOIN inventory i ON p.product_id = i.product_id
GROUP BY p.product_id, p.product_name, p.sku, pc.category_name, p.unit_price, p.cost_price, p.is_active;

CREATE UNIQUE INDEX idx_mv_product_pk ON mv_product_performance(product_id);
CREATE INDEX idx_mv_product_revenue ON mv_product_performance(total_revenue DESC);
CREATE INDEX idx_mv_product_rating ON mv_product_performance(avg_rating DESC);

COMMENT ON MATERIALIZED VIEW mv_product_performance IS 'Product sales metrics with profitability analysis';

-- ============================================================================
-- 4. Daily Sales Summary Materialized View
-- ============================================================================
CREATE MATERIALIZED VIEW mv_daily_sales AS
SELECT 
    DATE(order_date) as sale_date,
    COUNT(DISTINCT order_id) as order_count,
    COUNT(DISTINCT customer_id) as unique_customers,
    SUM(subtotal) as gross_sales,
    SUM(discount_amount) as total_discounts,
    SUM(tax_amount) as total_tax,
    SUM(shipping_cost) as shipping_revenue,
    SUM(total_amount) as net_sales,
    AVG(total_amount) as avg_order_value,
    MIN(total_amount) as min_order,
    MAX(total_amount) as max_order,
    -- Year-over-year comparison (if data available)
    LAG(SUM(total_amount)) OVER (ORDER BY DATE(order_date)) as prev_day_sales,
    SUM(total_amount) - LAG(SUM(total_amount)) OVER (ORDER BY DATE(order_date)) as day_over_day_change
FROM orders
WHERE order_status NOT IN ('CANCELLED', 'REFUNDED')
GROUP BY DATE(order_date);

CREATE UNIQUE INDEX idx_mv_daily_sales_date ON mv_daily_sales(sale_date);
CREATE INDEX idx_mv_daily_sales_recent ON mv_daily_sales(sale_date DESC);

COMMENT ON MATERIALIZED VIEW mv_daily_sales IS 'Daily sales aggregations for reporting dashboards';

-- ============================================================================
-- 5. Category Performance Materialized View
-- ============================================================================
CREATE MATERIALIZED VIEW mv_category_performance AS
WITH category_sales AS (
    SELECT 
        pc.category_id,
        pc.category_name,
        pc.parent_category_id,
        COUNT(DISTINCT p.product_id) as product_count,
        COUNT(DISTINCT oi.order_id) as order_count,
        COALESCE(SUM(oi.quantity), 0) as units_sold,
        COALESCE(SUM(oi.line_total), 0) as revenue,
        COALESCE(AVG(oi.unit_price), 0) as avg_price,
        COALESCE(AVG(r.rating), 0) as avg_rating,
        COUNT(DISTINCT r.review_id) as review_count
    FROM product_categories pc
    LEFT JOIN products p ON pc.category_id = p.category_id
    LEFT JOIN order_items oi ON p.product_id = oi.product_id
    LEFT JOIN reviews r ON p.product_id = r.product_id
    GROUP BY pc.category_id, pc.category_name, pc.parent_category_id
)
SELECT 
    cs.*,
    RANK() OVER (ORDER BY cs.revenue DESC) as revenue_rank,
    NTILE(4) OVER (ORDER BY cs.revenue) as revenue_quartile,
    CASE 
        WHEN cs.revenue > (SELECT AVG(revenue) FROM category_sales) * 1.5 THEN 'Top Performer'
        WHEN cs.revenue > (SELECT AVG(revenue) FROM category_sales) THEN 'Above Average'
        WHEN cs.revenue > (SELECT AVG(revenue) FROM category_sales) * 0.5 THEN 'Average'
        ELSE 'Below Average'
    END as performance_category
FROM category_sales cs;

CREATE UNIQUE INDEX idx_mv_category_pk ON mv_category_performance(category_id);
CREATE INDEX idx_mv_category_revenue ON mv_category_performance(revenue DESC);

COMMENT ON MATERIALIZED VIEW mv_category_performance IS 'Category-level sales analysis with rankings';

-- ============================================================================
-- 6. Customer Segmentation Materialized View
-- ============================================================================
CREATE MATERIALIZED VIEW mv_customer_segments AS
WITH customer_metrics AS (
    SELECT 
        c.customer_id,
        c.customer_tier,
        COUNT(DISTINCT o.order_id) as order_count,
        SUM(o.total_amount) as total_spent,
        AVG(o.total_amount) as avg_order_value,
        MAX(o.order_date) as last_order_date,
        EXTRACT(DAY FROM CURRENT_TIMESTAMP - MAX(o.order_date)) as recency_days,
        MIN(o.order_date) as first_order_date,
        EXTRACT(DAY FROM CURRENT_TIMESTAMP - MIN(o.order_date)) as customer_age_days
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id 
        AND o.order_status NOT IN ('CANCELLED', 'REFUNDED')
    WHERE c.is_active = TRUE
    GROUP BY c.customer_id, c.customer_tier
)
SELECT 
    customer_id,
    customer_tier,
    order_count,
    ROUND(total_spent, 2) as total_spent,
    ROUND(avg_order_value, 2) as avg_order_value,
    last_order_date,
    recency_days,
    NTILE(5) OVER (ORDER BY total_spent DESC) as spending_quintile,
    NTILE(5) OVER (ORDER BY order_count DESC) as frequency_quintile,
    NTILE(5) OVER (ORDER BY recency_days ASC) as recency_quintile,
    CASE 
        WHEN recency_days <= 30 AND order_count >= 5 AND total_spent >= 1000 THEN 'Champions'
        WHEN recency_days <= 60 AND order_count >= 3 AND total_spent >= 500 THEN 'Loyal'
        WHEN recency_days <= 30 AND order_count <= 2 THEN 'New'
        WHEN recency_days BETWEEN 61 AND 120 AND order_count >= 3 THEN 'At Risk'
        WHEN recency_days > 120 THEN 'Lost'
        ELSE 'Standard'
    END as rfm_segment,
    CASE 
        WHEN total_spent >= 5000 THEN 'High Value'
        WHEN total_spent >= 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END as value_segment
FROM customer_metrics;

CREATE UNIQUE INDEX idx_mv_segments_pk ON mv_customer_segments(customer_id);
CREATE INDEX idx_mv_segments_rfm ON mv_customer_segments(rfm_segment);
CREATE INDEX idx_mv_segments_value ON mv_customer_segments(value_segment);

COMMENT ON MATERIALIZED VIEW mv_customer_segments IS 'RFM customer segmentation analysis';

-- ============================================================================
-- 7. Monthly Revenue Trend Materialized View
-- ============================================================================
CREATE MATERIALIZED VIEW mv_monthly_revenue AS
WITH monthly_data AS (
    SELECT 
        DATE_TRUNC('month', order_date) as month,
        COUNT(DISTINCT order_id) as order_count,
        COUNT(DISTINCT customer_id) as unique_customers,
        SUM(total_amount) as revenue,
        AVG(total_amount) as avg_order_value,
        SUM(discount_amount) as discounts_given
    FROM orders
    WHERE order_status NOT IN ('CANCELLED', 'REFUNDED')
    GROUP BY DATE_TRUNC('month', order_date)
)
SELECT 
    month,
    order_count,
    unique_customers,
    ROUND(revenue, 2) as revenue,
    ROUND(avg_order_value, 2) as avg_order_value,
    ROUND(discounts_given, 2) as discounts_given,
    ROUND((discounts_given / NULLIF(revenue + discounts_given, 0)) * 100, 2) as discount_percentage,
    LAG(revenue) OVER (ORDER BY month) as prev_month_revenue,
    ROUND(((revenue - LAG(revenue) OVER (ORDER BY month)) / NULLIF(LAG(revenue) OVER (ORDER BY month), 0)) * 100, 2) as revenue_growth_pct,
    SUM(revenue) OVER (ORDER BY month) as cumulative_revenue
FROM monthly_data;

CREATE UNIQUE INDEX idx_mv_monthly_month ON mv_monthly_revenue(month);

COMMENT ON MATERIALIZED VIEW mv_monthly_revenue IS 'Monthly revenue trends with growth calculations';

-- ============================================================================
-- 8. Inventory Status Materialized View
-- ============================================================================
CREATE MATERIALIZED VIEW mv_inventory_status AS
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
    p.unit_price * i.quantity_available as inventory_value,
    i.last_restocked_at,
    EXTRACT(DAY FROM CURRENT_TIMESTAMP - i.last_restocked_at) as days_since_restock,
    -- Sales velocity (last 30 days)
    COALESCE((
        SELECT SUM(oi.quantity)
        FROM order_items oi
        JOIN orders o ON oi.order_id = o.order_id
        WHERE oi.product_id = p.product_id
            AND o.order_date >= CURRENT_DATE - INTERVAL '30 days'
            AND o.order_status NOT IN ('CANCELLED', 'REFUNDED')
    ), 0) as units_sold_last_30_days,
    -- Days until stockout (if no reorder)
    CASE 
        WHEN COALESCE((
            SELECT SUM(oi.quantity)
            FROM order_items oi
            JOIN orders o ON oi.order_id = o.order_id
            WHERE oi.product_id = p.product_id
                AND o.order_date >= CURRENT_DATE - INTERVAL '30 days'
                AND o.order_status NOT IN ('CANCELLED', 'REFUNDED')
        ), 0) > 0 
        THEN ROUND((i.quantity_available * 30.0) / NULLIF(COALESCE((
            SELECT SUM(oi.quantity)
            FROM order_items oi
            JOIN orders o ON oi.order_id = o.order_id
            WHERE oi.product_id = p.product_id
                AND o.order_date >= CURRENT_DATE - INTERVAL '30 days'
                AND o.order_status NOT IN ('CANCELLED', 'REFUNDED')
        ), 0), 0), 0)
        ELSE NULL
    END as estimated_days_to_stockout
FROM inventory i
INNER JOIN products p ON i.product_id = p.product_id
INNER JOIN product_categories pc ON p.category_id = pc.category_id
WHERE p.is_active = TRUE;

CREATE UNIQUE INDEX idx_mv_inventory_pk ON mv_inventory_status(inventory_id);
CREATE INDEX idx_mv_inventory_status_filter ON mv_inventory_status(stock_status);
CREATE INDEX idx_mv_inventory_product ON mv_inventory_status(product_id);

COMMENT ON MATERIALIZED VIEW mv_inventory_status IS 'Real-time inventory status with sales velocity';

-- ============================================================================
-- 9. Performance comparison: View vs Materialized View
-- ============================================================================
-- Regular view (computed on every query)
CREATE OR REPLACE VIEW v_product_sales AS
SELECT 
    p.product_id,
    p.product_name,
    COUNT(DISTINCT oi.order_id) as orders,
    SUM(oi.quantity) as units_sold,
    SUM(oi.line_total) as revenue
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name;

-- Query regular view (computes every time)
EXPLAIN ANALYZE
SELECT * FROM v_product_sales ORDER BY revenue DESC LIMIT 10;

-- Query materialized view (pre-computed, much faster)
EXPLAIN ANALYZE
SELECT * FROM mv_product_performance ORDER BY total_revenue DESC LIMIT 10;

-- ============================================================================
-- 10. Automated refresh strategy
-- ============================================================================
-- Function to refresh all materialized views
CREATE OR REPLACE FUNCTION refresh_all_materialized_views()
RETURNS void AS $$
DECLARE
    mv_record RECORD;
BEGIN
    FOR mv_record IN 
        SELECT schemaname, matviewname
        FROM pg_matviews
        WHERE schemaname = 'public'
        ORDER BY matviewname
    LOOP
        RAISE NOTICE 'Refreshing materialized view: %.%', mv_record.schemaname, mv_record.matviewname;
        
        BEGIN
            EXECUTE format('REFRESH MATERIALIZED VIEW CONCURRENTLY %I.%I', 
                mv_record.schemaname, mv_record.matviewname);
        EXCEPTION
            WHEN OTHERS THEN
                -- If concurrent refresh fails, try regular refresh
                RAISE NOTICE 'Concurrent refresh failed, trying regular refresh';
                EXECUTE format('REFRESH MATERIALIZED VIEW %I.%I', 
                    mv_record.schemaname, mv_record.matviewname);
        END;
    END LOOP;
    
    RAISE NOTICE 'All materialized views refreshed successfully';
END;
$$ LANGUAGE plpgsql;

-- Execute refresh
-- SELECT refresh_all_materialized_views();

-- ============================================================================
-- 11. Materialized view refresh monitoring
-- ============================================================================
-- Check when materialized views were last refreshed
-- Note: PostgreSQL doesn't track this natively, but we included timestamps in some views

SELECT 
    schemaname,
    matviewname,
    pg_size_pretty(pg_total_relation_size(schemaname || '.' || matviewname)) as size,
    (SELECT COUNT(*) FROM pg_indexes WHERE tablename = matviewname) as index_count
FROM pg_matviews
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname || '.' || matviewname) DESC;

-- ============================================================================
-- 12. Incremental refresh pattern (manual implementation)
-- ============================================================================
-- Create tracking table for incremental updates
CREATE TABLE IF NOT EXISTS mv_refresh_log (
    mv_name VARCHAR(100),
    last_refresh_time TIMESTAMP,
    rows_affected INTEGER,
    refresh_duration INTERVAL,
    PRIMARY KEY (mv_name)
);

-- Function for incremental refresh
CREATE OR REPLACE FUNCTION incremental_refresh_daily_sales()
RETURNS void AS $$
DECLARE
    v_start_time TIMESTAMP := clock_timestamp();
    v_last_refresh TIMESTAMP;
    v_rows_affected INTEGER;
BEGIN
    -- Get last refresh time
    SELECT last_refresh_time INTO v_last_refresh
    FROM mv_refresh_log
    WHERE mv_name = 'mv_daily_sales';
    
    -- Delete and re-insert only changed data
    DELETE FROM mv_daily_sales
    WHERE sale_date >= COALESCE(v_last_refresh, '1900-01-01'::DATE);
    
    INSERT INTO mv_daily_sales
    SELECT 
        DATE(order_date) as sale_date,
        COUNT(DISTINCT order_id) as order_count,
        COUNT(DISTINCT customer_id) as unique_customers,
        SUM(subtotal) as gross_sales,
        SUM(discount_amount) as total_discounts,
        SUM(tax_amount) as total_tax,
        SUM(shipping_cost) as shipping_revenue,
        SUM(total_amount) as net_sales,
        AVG(total_amount) as avg_order_value,
        MIN(total_amount) as min_order,
        MAX(total_amount) as max_order,
        NULL as prev_day_sales,
        NULL as day_over_day_change
    FROM orders
    WHERE order_status NOT IN ('CANCELLED', 'REFUNDED')
        AND DATE(order_date) >= COALESCE(v_last_refresh, '1900-01-01'::DATE)
    GROUP BY DATE(order_date);
    
    GET DIAGNOSTICS v_rows_affected = ROW_COUNT;
    
    -- Log the refresh
    INSERT INTO mv_refresh_log (mv_name, last_refresh_time, rows_affected, refresh_duration)
    VALUES ('mv_daily_sales', CURRENT_TIMESTAMP, v_rows_affected, clock_timestamp() - v_start_time)
    ON CONFLICT (mv_name) 
    DO UPDATE SET 
        last_refresh_time = EXCLUDED.last_refresh_time,
        rows_affected = EXCLUDED.rows_affected,
        refresh_duration = EXCLUDED.refresh_duration;
    
    RAISE NOTICE 'Incremental refresh completed: % rows affected in %', 
        v_rows_affected, clock_timestamp() - v_start_time;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 13. Best practices summary
-- ============================================================================
/*
MATERIALIZED VIEW BEST PRACTICES:

1. Use for expensive queries run frequently
2. Create unique indexes to enable CONCURRENT refresh
3. Schedule regular refreshes based on data freshness needs
4. Monitor view sizes and query performance
5. Consider incremental refresh for large views
6. Document refresh schedules and dependencies
7. Balance freshness vs. refresh cost
8. Use for aggregations, not transactional data
9. Create indexes on commonly filtered columns
10. Test query performance before/after materialization
11. Consider maintenance window for non-concurrent refreshes
12. Monitor disk space usage
13. Use for dashboard and reporting queries
14. Avoid for real-time requirements
15. Combine with regular caching strategies

WHEN TO USE MATERIALIZED VIEWS:
- Complex aggregations run frequently
- Reports and dashboards
- Data doesn't need to be real-time
- Query is expensive (>1 second)
- Underlying tables change infrequently
- Multiple users run same queries

WHEN NOT TO USE:
- Data must be real-time
- Underlying data changes very frequently
- Simple queries that are already fast
- Limited disk space
- Cannot accommodate refresh windows
*/

-- ============================================================================
-- Clean up (optional)
-- ============================================================================
-- DROP MATERIALIZED VIEW IF EXISTS mv_customer_analytics CASCADE;
-- DROP MATERIALIZED VIEW IF EXISTS mv_product_performance CASCADE;
-- DROP MATERIALIZED VIEW IF EXISTS mv_daily_sales CASCADE;
-- DROP MATERIALIZED VIEW IF EXISTS mv_category_performance CASCADE;
-- DROP MATERIALIZED VIEW IF EXISTS mv_customer_segments CASCADE;
-- DROP MATERIALIZED VIEW IF EXISTS mv_monthly_revenue CASCADE;
-- DROP MATERIALIZED VIEW IF EXISTS mv_inventory_status CASCADE;
-- DROP VIEW IF EXISTS v_product_sales CASCADE;
-- DROP TABLE IF EXISTS mv_refresh_log CASCADE;
-- DROP FUNCTION IF EXISTS refresh_all_materialized_views();
-- DROP FUNCTION IF EXISTS incremental_refresh_daily_sales();

-- ============================================================================
-- Summary
-- ============================================================================
COMMENT ON MATERIALIZED VIEW mv_customer_analytics IS 
'This file demonstrates: Creating materialized views, refreshing (regular and
concurrent), creating indexes on MVs, performance comparison with regular views,
automated refresh strategies, incremental refresh patterns, refresh monitoring,
and best practices for when and how to use materialized views effectively';


