-- ============================================================================
-- Ordering and Grouping Queries
-- ============================================================================
-- Competency: Orders and groups data from a database using query language
-- Description: Demonstrates ORDER BY, GROUP BY, HAVING, and aggregate functions
-- ============================================================================

-- ============================================================================
-- 1. Simple ORDER BY - Ascending
-- ============================================================================
-- List products by price (lowest to highest)
SELECT 
    product_id,
    product_name,
    unit_price
FROM products
ORDER BY unit_price ASC;

-- ============================================================================
-- 2. ORDER BY - Descending
-- ============================================================================
-- List products by price (highest to lowest)
SELECT 
    product_id,
    product_name,
    unit_price
FROM products
ORDER BY unit_price DESC;

-- ============================================================================
-- 3. ORDER BY multiple columns
-- ============================================================================
-- Sort customers by tier (descending) then by last name (ascending)
SELECT 
    customer_id,
    first_name,
    last_name,
    customer_tier
FROM customers
ORDER BY customer_tier DESC, last_name ASC, first_name ASC;

-- ============================================================================
-- 4. ORDER BY with NULL handling
-- ============================================================================
-- List products, showing those without descriptions last
SELECT 
    product_id,
    product_name,
    description
FROM products
ORDER BY description NULLS LAST;

-- ============================================================================
-- 5. Basic GROUP BY with COUNT
-- ============================================================================
-- Count customers by tier
SELECT 
    customer_tier,
    COUNT(*) as customer_count
FROM customers
GROUP BY customer_tier
ORDER BY customer_count DESC;

-- ============================================================================
-- 6. GROUP BY with SUM
-- ============================================================================
-- Total revenue by order status
SELECT 
    order_status,
    COUNT(*) as order_count,
    SUM(total_amount) as total_revenue
FROM orders
GROUP BY order_status
ORDER BY total_revenue DESC;

-- ============================================================================
-- 7. GROUP BY with AVG
-- ============================================================================
-- Average order value by customer tier
SELECT 
    c.customer_tier,
    COUNT(o.order_id) as order_count,
    ROUND(AVG(o.total_amount), 2) as avg_order_value
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_status != 'CANCELLED'
GROUP BY c.customer_tier
ORDER BY avg_order_value DESC;

-- ============================================================================
-- 8. GROUP BY with MAX and MIN
-- ============================================================================
-- Price range by product category
SELECT 
    pc.category_name,
    COUNT(p.product_id) as product_count,
    MIN(p.unit_price) as lowest_price,
    MAX(p.unit_price) as highest_price,
    ROUND(AVG(p.unit_price), 2) as average_price
FROM product_categories pc
LEFT JOIN products p ON pc.category_id = p.category_id
GROUP BY pc.category_id, pc.category_name
ORDER BY average_price DESC;

-- ============================================================================
-- 9. GROUP BY with multiple aggregate functions
-- ============================================================================
-- Comprehensive order statistics by month
SELECT 
    DATE_TRUNC('month', order_date) as order_month,
    COUNT(*) as total_orders,
    COUNT(DISTINCT customer_id) as unique_customers,
    SUM(total_amount) as total_revenue,
    ROUND(AVG(total_amount), 2) as avg_order_value,
    MIN(total_amount) as min_order,
    MAX(total_amount) as max_order
FROM orders
WHERE order_status NOT IN ('CANCELLED', 'REFUNDED')
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY order_month DESC;

-- ============================================================================
-- 10. GROUP BY with HAVING clause
-- ============================================================================
-- Find customers who have placed more than 2 orders
SELECT 
    c.customer_id,
    c.first_name || ' ' || c.last_name as customer_name,
    COUNT(o.order_id) as order_count,
    SUM(o.total_amount) as total_spent
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_status != 'CANCELLED'
GROUP BY c.customer_id, c.first_name, c.last_name
HAVING COUNT(o.order_id) > 2
ORDER BY total_spent DESC;

-- ============================================================================
-- 11. HAVING with aggregate conditions
-- ============================================================================
-- Find products with average rating above 4.0 and more than 2 reviews
SELECT 
    p.product_id,
    p.product_name,
    COUNT(r.review_id) as review_count,
    ROUND(AVG(r.rating), 2) as avg_rating
FROM products p
JOIN reviews r ON p.product_id = r.product_id
GROUP BY p.product_id, p.product_name
HAVING COUNT(r.review_id) >= 2 AND AVG(r.rating) >= 4.0
ORDER BY avg_rating DESC, review_count DESC;

-- ============================================================================
-- 12. GROUP BY with date functions
-- ============================================================================
-- Sales by day of week
SELECT 
    TO_CHAR(order_date, 'Day') as day_of_week,
    EXTRACT(DOW FROM order_date) as day_number,
    COUNT(*) as order_count,
    ROUND(SUM(total_amount), 2) as daily_revenue
FROM orders
WHERE order_status NOT IN ('CANCELLED', 'REFUNDED')
GROUP BY EXTRACT(DOW FROM order_date), TO_CHAR(order_date, 'Day')
ORDER BY day_number;

-- ============================================================================
-- 13. GROUP BY with CASE in aggregate
-- ============================================================================
-- Count orders by status category
SELECT 
    CASE 
        WHEN order_status IN ('PENDING', 'CONFIRMED', 'PROCESSING') THEN 'In Progress'
        WHEN order_status IN ('SHIPPED', 'DELIVERED') THEN 'Completed'
        ELSE 'Other'
    END as status_category,
    COUNT(*) as order_count,
    SUM(total_amount) as total_value
FROM orders
GROUP BY status_category
ORDER BY order_count DESC;

-- ============================================================================
-- 14. Grouping by multiple columns
-- ============================================================================
-- Sales analysis by category and month
SELECT 
    DATE_TRUNC('month', o.order_date) as month,
    pc.category_name,
    COUNT(DISTINCT o.order_id) as orders,
    SUM(oi.quantity) as units_sold,
    ROUND(SUM(oi.line_total), 2) as category_revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
JOIN product_categories pc ON p.category_id = pc.category_id
WHERE o.order_status NOT IN ('CANCELLED', 'REFUNDED')
GROUP BY DATE_TRUNC('month', o.order_date), pc.category_name
ORDER BY month DESC, category_revenue DESC;

-- ============================================================================
-- 15. GROUP BY with ROLLUP (subtotals)
-- ============================================================================
-- Revenue by category with total
SELECT 
    pc.category_name,
    COUNT(DISTINCT o.order_id) as order_count,
    ROUND(SUM(oi.line_total), 2) as revenue
FROM product_categories pc
LEFT JOIN products p ON pc.category_id = p.category_id
LEFT JOIN order_items oi ON p.product_id = oi.product_id
LEFT JOIN orders o ON oi.order_id = o.order_id AND o.order_status != 'CANCELLED'
GROUP BY ROLLUP(pc.category_name)
ORDER BY revenue DESC NULLS LAST;

-- ============================================================================
-- 16. Window functions with ORDER BY (OVER clause)
-- ============================================================================
-- Rank products by revenue within their category
SELECT 
    p.product_id,
    p.product_name,
    pc.category_name,
    COALESCE(SUM(oi.line_total), 0) as total_revenue,
    RANK() OVER (PARTITION BY pc.category_name ORDER BY COALESCE(SUM(oi.line_total), 0) DESC) as category_rank
FROM products p
JOIN product_categories pc ON p.category_id = pc.category_id
LEFT JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name, pc.category_name
ORDER BY pc.category_name, category_rank;

-- ============================================================================
-- 17. Running totals with window functions
-- ============================================================================
-- Calculate running total of daily revenue
SELECT 
    DATE(order_date) as order_date,
    COUNT(*) as daily_orders,
    ROUND(SUM(total_amount), 2) as daily_revenue,
    ROUND(SUM(SUM(total_amount)) OVER (ORDER BY DATE(order_date)), 2) as running_total
FROM orders
WHERE order_status NOT IN ('CANCELLED', 'REFUNDED')
GROUP BY DATE(order_date)
ORDER BY order_date;

-- ============================================================================
-- 18. Moving averages with window functions
-- ============================================================================
-- Calculate 3-day moving average of orders
SELECT 
    DATE(order_date) as order_date,
    COUNT(*) as daily_orders,
    ROUND(AVG(COUNT(*)) OVER (
        ORDER BY DATE(order_date) 
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2) as three_day_avg_orders
FROM orders
WHERE order_status NOT IN ('CANCELLED', 'REFUNDED')
GROUP BY DATE(order_date)
ORDER BY order_date;

-- ============================================================================
-- 19. Percentile calculations
-- ============================================================================
-- Find products in different revenue percentiles
SELECT 
    p.product_id,
    p.product_name,
    ROUND(COALESCE(SUM(oi.line_total), 0), 2) as total_revenue,
    PERCENT_RANK() OVER (ORDER BY COALESCE(SUM(oi.line_total), 0)) as percentile,
    NTILE(4) OVER (ORDER BY COALESCE(SUM(oi.line_total), 0)) as quartile
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name
ORDER BY total_revenue DESC;

-- ============================================================================
-- 20. Complex grouping with filtered aggregates
-- ============================================================================
-- Customer statistics with conditional aggregation
SELECT 
    c.customer_id,
    c.first_name || ' ' || c.last_name as customer_name,
    c.customer_tier,
    COUNT(o.order_id) as total_orders,
    SUM(CASE WHEN o.order_status = 'DELIVERED' THEN 1 ELSE 0 END) as delivered_orders,
    SUM(CASE WHEN o.order_status = 'CANCELLED' THEN 1 ELSE 0 END) as cancelled_orders,
    ROUND(SUM(CASE WHEN o.order_status != 'CANCELLED' THEN o.total_amount ELSE 0 END), 2) as total_spent,
    ROUND(AVG(CASE WHEN o.order_status != 'CANCELLED' THEN o.total_amount END), 2) as avg_order_value
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name, c.customer_tier
HAVING COUNT(o.order_id) > 0
ORDER BY total_spent DESC;

-- ============================================================================
-- Summary
-- ============================================================================
COMMENT ON TABLE orders IS 
'These queries demonstrate: ORDER BY (single/multiple columns), GROUP BY, 
aggregate functions (COUNT, SUM, AVG, MIN, MAX), HAVING clause, 
date grouping, window functions (RANK, RUNNING TOTALS, MOVING AVERAGES), 
ROLLUP for subtotals, and complex conditional aggregation';


