-- ============================================================================
-- Complex Query Optimization Examples
-- ============================================================================
-- Competency: Combines multiple queries to optimise query execution
-- Description: Demonstrates JOINs, subqueries, CTEs, and query optimization techniques
-- ============================================================================

-- ============================================================================
-- 1. INNER JOIN - Basic relationship
-- ============================================================================
-- Get orders with customer information
SELECT 
    o.order_id,
    o.order_date,
    c.first_name,
    c.last_name,
    c.email,
    o.total_amount
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
ORDER BY o.order_date DESC;

-- ============================================================================
-- 2. LEFT JOIN - Include records even without matches
-- ============================================================================
-- Get all products with their inventory (including products without inventory)
SELECT 
    p.product_id,
    p.product_name,
    p.unit_price,
    COALESCE(i.quantity_available, 0) as available_stock,
    COALESCE(i.warehouse_location, 'No inventory') as warehouse
FROM products p
LEFT JOIN inventory i ON p.product_id = i.product_id
ORDER BY p.product_name;

-- ============================================================================
-- 3. RIGHT JOIN
-- ============================================================================
-- Show all inventory with product details (even orphaned inventory)
SELECT 
    i.inventory_id,
    i.warehouse_location,
    i.quantity_available,
    p.product_name,
    p.sku
FROM products p
RIGHT JOIN inventory i ON p.product_id = i.product_id;

-- ============================================================================
-- 4. FULL OUTER JOIN
-- ============================================================================
-- Show all products and all inventory (even if unmatched)
SELECT 
    COALESCE(p.product_id, i.product_id) as product_id,
    p.product_name,
    i.warehouse_location,
    i.quantity_available
FROM products p
FULL OUTER JOIN inventory i ON p.product_id = i.product_id;

-- ============================================================================
-- 5. Multiple JOINs
-- ============================================================================
-- Complete order information with customer and product details
SELECT 
    o.order_id,
    o.order_date,
    c.first_name || ' ' || c.last_name as customer_name,
    c.email,
    p.product_name,
    oi.quantity,
    oi.unit_price,
    oi.line_total
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
INNER JOIN order_items oi ON o.order_id = oi.order_id
INNER JOIN products p ON oi.product_id = p.product_id
WHERE o.order_status != 'CANCELLED'
ORDER BY o.order_date DESC, o.order_id;

-- ============================================================================
-- 6. Self JOIN - Hierarchical data
-- ============================================================================
-- Show category hierarchy (parent and child categories)
SELECT 
    parent.category_name as parent_category,
    child.category_name as child_category,
    child.description
FROM product_categories child
LEFT JOIN product_categories parent ON child.parent_category_id = parent.category_id
ORDER BY parent.category_name, child.category_name;

-- ============================================================================
-- 7. Simple subquery in WHERE clause
-- ============================================================================
-- Find customers who have spent more than the average
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    SUM(o.total_amount) as total_spent
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_status != 'CANCELLED'
GROUP BY c.customer_id, c.first_name, c.last_name
HAVING SUM(o.total_amount) > (
    SELECT AVG(customer_total)
    FROM (
        SELECT customer_id, SUM(total_amount) as customer_total
        FROM orders
        WHERE order_status != 'CANCELLED'
        GROUP BY customer_id
    ) as customer_totals
)
ORDER BY total_spent DESC;

-- ============================================================================
-- 8. Correlated subquery
-- ============================================================================
-- Find products that are priced above their category average
SELECT 
    p.product_id,
    p.product_name,
    pc.category_name,
    p.unit_price,
    (
        SELECT ROUND(AVG(p2.unit_price), 2)
        FROM products p2
        WHERE p2.category_id = p.category_id
    ) as category_avg_price
FROM products p
JOIN product_categories pc ON p.category_id = pc.category_id
WHERE p.unit_price > (
    SELECT AVG(p2.unit_price)
    FROM products p2
    WHERE p2.category_id = p.category_id
)
ORDER BY pc.category_name, p.unit_price DESC;

-- ============================================================================
-- 9. Subquery in SELECT clause
-- ============================================================================
-- Customer summary with subqueries
SELECT 
    c.customer_id,
    c.first_name || ' ' || c.last_name as customer_name,
    (
        SELECT COUNT(*)
        FROM orders o
        WHERE o.customer_id = c.customer_id AND o.order_status != 'CANCELLED'
    ) as order_count,
    (
        SELECT COALESCE(SUM(total_amount), 0)
        FROM orders o
        WHERE o.customer_id = c.customer_id AND o.order_status != 'CANCELLED'
    ) as lifetime_value,
    (
        SELECT COUNT(*)
        FROM reviews r
        WHERE r.customer_id = c.customer_id
    ) as review_count
FROM customers c
WHERE c.is_active = TRUE
ORDER BY lifetime_value DESC;

-- ============================================================================
-- 10. EXISTS subquery
-- ============================================================================
-- Find customers who have written at least one review
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    c.email
FROM customers c
WHERE EXISTS (
    SELECT 1
    FROM reviews r
    WHERE r.customer_id = c.customer_id
)
ORDER BY c.last_name;

-- ============================================================================
-- 11. NOT EXISTS subquery
-- ============================================================================
-- Find products that have never been ordered
SELECT 
    p.product_id,
    p.product_name,
    p.unit_price,
    pc.category_name
FROM products p
JOIN product_categories pc ON p.category_id = pc.category_id
WHERE NOT EXISTS (
    SELECT 1
    FROM order_items oi
    WHERE oi.product_id = p.product_id
)
AND p.is_active = TRUE;

-- ============================================================================
-- 12. Simple CTE (Common Table Expression)
-- ============================================================================
-- Calculate customer metrics using CTE
WITH customer_orders AS (
    SELECT 
        customer_id,
        COUNT(*) as order_count,
        SUM(total_amount) as total_spent,
        AVG(total_amount) as avg_order_value
    FROM orders
    WHERE order_status != 'CANCELLED'
    GROUP BY customer_id
)
SELECT 
    c.customer_id,
    c.first_name || ' ' || c.last_name as customer_name,
    c.customer_tier,
    co.order_count,
    ROUND(co.total_spent, 2) as total_spent,
    ROUND(co.avg_order_value, 2) as avg_order_value
FROM customers c
JOIN customer_orders co ON c.customer_id = co.customer_id
WHERE co.order_count >= 2
ORDER BY co.total_spent DESC;

-- ============================================================================
-- 13. Multiple CTEs
-- ============================================================================
-- Complex analysis using multiple CTEs
WITH product_sales AS (
    SELECT 
        p.product_id,
        p.product_name,
        p.category_id,
        COUNT(DISTINCT oi.order_id) as times_ordered,
        SUM(oi.quantity) as total_units_sold,
        SUM(oi.line_total) as total_revenue
    FROM products p
    LEFT JOIN order_items oi ON p.product_id = oi.product_id
    GROUP BY p.product_id, p.product_name, p.category_id
),
product_reviews AS (
    SELECT 
        product_id,
        COUNT(*) as review_count,
        AVG(rating) as avg_rating
    FROM reviews
    GROUP BY product_id
)
SELECT 
    ps.product_id,
    ps.product_name,
    pc.category_name,
    COALESCE(ps.times_ordered, 0) as times_ordered,
    COALESCE(ps.total_units_sold, 0) as units_sold,
    ROUND(COALESCE(ps.total_revenue, 0), 2) as revenue,
    COALESCE(pr.review_count, 0) as reviews,
    ROUND(COALESCE(pr.avg_rating, 0), 2) as avg_rating
FROM product_sales ps
JOIN product_categories pc ON ps.category_id = pc.category_id
LEFT JOIN product_reviews pr ON ps.product_id = pr.product_id
WHERE ps.total_revenue > 0
ORDER BY ps.total_revenue DESC;

-- ============================================================================
-- 14. Recursive CTE - Category hierarchy
-- ============================================================================
-- Build complete category tree with all levels
WITH RECURSIVE category_tree AS (
    -- Base case: top-level categories
    SELECT 
        category_id,
        category_name,
        parent_category_id,
        1 as level,
        category_name::TEXT as path
    FROM product_categories
    WHERE parent_category_id IS NULL
    
    UNION ALL
    
    -- Recursive case: child categories
    SELECT 
        pc.category_id,
        pc.category_name,
        pc.parent_category_id,
        ct.level + 1,
        ct.path || ' > ' || pc.category_name
    FROM product_categories pc
    INNER JOIN category_tree ct ON pc.parent_category_id = ct.category_id
)
SELECT 
    category_id,
    REPEAT('  ', level - 1) || category_name as indented_name,
    level,
    path
FROM category_tree
ORDER BY path;

-- ============================================================================
-- 15. CTE for data transformation
-- ============================================================================
-- Transform order data for monthly reporting
WITH monthly_orders AS (
    SELECT 
        DATE_TRUNC('month', order_date) as month,
        customer_id,
        order_id,
        total_amount
    FROM orders
    WHERE order_status NOT IN ('CANCELLED', 'REFUNDED')
),
customer_monthly_summary AS (
    SELECT 
        month,
        COUNT(DISTINCT customer_id) as unique_customers,
        COUNT(order_id) as order_count,
        SUM(total_amount) as monthly_revenue,
        AVG(total_amount) as avg_order_value
    FROM monthly_orders
    GROUP BY month
)
SELECT 
    TO_CHAR(month, 'YYYY-MM') as month,
    unique_customers,
    order_count,
    ROUND(monthly_revenue, 2) as revenue,
    ROUND(avg_order_value, 2) as avg_order_value,
    ROUND(monthly_revenue / NULLIF(unique_customers, 0), 2) as revenue_per_customer
FROM customer_monthly_summary
ORDER BY month DESC;

-- ============================================================================
-- 16. Query optimization: JOIN vs subquery comparison
-- ============================================================================
-- APPROACH 1: Using JOIN (usually more efficient)
EXPLAIN ANALYZE
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    COUNT(o.order_id) as order_count
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY order_count DESC;

-- APPROACH 2: Using subquery
EXPLAIN ANALYZE
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    (SELECT COUNT(*) FROM orders o WHERE o.customer_id = c.customer_id) as order_count
FROM customers c
ORDER BY order_count DESC;

-- ============================================================================
-- 17. UNION - Combine result sets
-- ============================================================================
-- List all high-value items (products over $1000 or orders over $1000)
SELECT 
    'Product' as item_type,
    product_id as id,
    product_name as description,
    unit_price as amount
FROM products
WHERE unit_price > 1000

UNION

SELECT 
    'Order' as item_type,
    order_id as id,
    'Order #' || order_id as description,
    total_amount as amount
FROM orders
WHERE total_amount > 1000 AND order_status != 'CANCELLED'

ORDER BY amount DESC;

-- ============================================================================
-- 18. UNION ALL - Include duplicates (faster than UNION)
-- ============================================================================
-- Combine all transactions
SELECT 
    order_id as transaction_id,
    'ORDER' as transaction_type,
    order_date as transaction_date,
    total_amount as amount
FROM orders

UNION ALL

SELECT 
    promotion_id,
    'PROMOTION_CREATED',
    start_date,
    discount_value
FROM promotions

ORDER BY transaction_date DESC;

-- ============================================================================
-- 19. INTERSECT - Find common records
-- ============================================================================
-- Find customers who are both reviewers and have high-value orders
SELECT customer_id FROM reviews

INTERSECT

SELECT customer_id 
FROM orders 
WHERE total_amount > 1000;

-- ============================================================================
-- 20. EXCEPT - Find differences
-- ============================================================================
-- Find customers who have ordered but never reviewed
SELECT DISTINCT customer_id FROM orders

EXCEPT

SELECT DISTINCT customer_id FROM reviews;

-- ============================================================================
-- 21. Complex multi-level query with CTEs and window functions
-- ============================================================================
-- Customer segmentation analysis
WITH customer_metrics AS (
    SELECT 
        c.customer_id,
        c.first_name || ' ' || c.last_name as customer_name,
        c.customer_tier,
        COUNT(DISTINCT o.order_id) as order_count,
        SUM(o.total_amount) as total_spent,
        AVG(o.total_amount) as avg_order_value,
        MAX(o.order_date) as last_order_date,
        MIN(o.order_date) as first_order_date
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id 
        AND o.order_status NOT IN ('CANCELLED', 'REFUNDED')
    WHERE c.is_active = TRUE
    GROUP BY c.customer_id, c.first_name, c.last_name, c.customer_tier
),
customer_ranked AS (
    SELECT 
        *,
        NTILE(4) OVER (ORDER BY total_spent) as spending_quartile,
        NTILE(4) OVER (ORDER BY order_count) as frequency_quartile,
        EXTRACT(DAY FROM CURRENT_TIMESTAMP - last_order_date) as days_since_last_order
    FROM customer_metrics
    WHERE order_count > 0
)
SELECT 
    customer_id,
    customer_name,
    customer_tier,
    order_count,
    ROUND(total_spent, 2) as total_spent,
    ROUND(avg_order_value, 2) as avg_order_value,
    spending_quartile,
    frequency_quartile,
    days_since_last_order,
    CASE 
        WHEN spending_quartile = 4 AND frequency_quartile = 4 THEN 'VIP'
        WHEN spending_quartile >= 3 AND frequency_quartile >= 3 THEN 'Loyal'
        WHEN days_since_last_order > 90 THEN 'At Risk'
        ELSE 'Standard'
    END as customer_segment
FROM customer_ranked
ORDER BY total_spent DESC;

-- ============================================================================
-- Summary
-- ============================================================================
COMMENT ON TABLE order_items IS 
'These queries demonstrate: INNER/LEFT/RIGHT/FULL JOINs, multiple JOINs, 
self JOINs, subqueries (WHERE/SELECT/FROM), correlated subqueries, 
EXISTS/NOT EXISTS, CTEs, recursive CTEs, UNION/UNION ALL/INTERSECT/EXCEPT, 
query optimization techniques, and complex multi-level analytical queries';


