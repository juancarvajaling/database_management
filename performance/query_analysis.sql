-- ============================================================================
-- Query Performance Analysis and Optimization
-- ============================================================================
-- Competency: Optimises query performance using query techniques and methodologies
-- Description: Demonstrates EXPLAIN, EXPLAIN ANALYZE, and query optimization techniques
-- ============================================================================

-- ============================================================================
-- 1. EXPLAIN - See query execution plan
-- ============================================================================
-- Basic EXPLAIN shows the plan without executing
EXPLAIN
SELECT * FROM orders WHERE customer_id = 5;

-- Reading EXPLAIN output:
-- - Seq Scan = Sequential scan (reads entire table)
-- - Index Scan = Uses an index
-- - cost = estimated cost (startup..total)
-- - rows = estimated rows returned
-- - width = average row size in bytes

-- ============================================================================
-- 2. EXPLAIN ANALYZE - Execute and show actual performance
-- ============================================================================
-- EXPLAIN ANALYZE actually runs the query and shows real metrics
EXPLAIN ANALYZE
SELECT * FROM orders WHERE customer_id = 5;

-- Additional metrics shown:
-- - actual time = real execution time
-- - actual rows = actual rows returned
-- - loops = number of times node was executed

-- ============================================================================
-- 3. EXPLAIN options for detailed analysis
-- ============================================================================
-- Show all available information
EXPLAIN (ANALYZE, VERBOSE, BUFFERS, COSTS, TIMING)
SELECT 
    o.order_id,
    o.order_date,
    c.first_name || ' ' || c.last_name as customer_name,
    o.total_amount
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_date > '2024-01-01';

-- BUFFERS shows I/O operations
-- VERBOSE shows column lists
-- COSTS shows cost estimates (default)
-- TIMING shows timing information

-- ============================================================================
-- 4. Identifying sequential scans that need indexes
-- ============================================================================
-- This query performs a sequential scan (slow for large tables)
EXPLAIN ANALYZE
SELECT * FROM orders WHERE order_status = 'PROCESSING';

-- Create an index to improve it
CREATE INDEX IF NOT EXISTS idx_demo_order_status ON orders(order_status);

-- Now it should use index scan (faster)
EXPLAIN ANALYZE
SELECT * FROM orders WHERE order_status = 'PROCESSING';

-- ============================================================================
-- 5. Analyzing JOIN performance
-- ============================================================================
-- Nested Loop join (good for small result sets)
EXPLAIN ANALYZE
SELECT 
    o.order_id,
    c.customer_tier,
    o.total_amount
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_id = 5;

-- Hash Join (good for larger result sets)
EXPLAIN ANALYZE
SELECT 
    c.customer_id,
    c.first_name,
    COUNT(o.order_id) as order_count
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.first_name;

-- Merge Join (good for pre-sorted data)
SET enable_hashjoin = off;
SET enable_nestloop = off;

EXPLAIN ANALYZE
SELECT 
    c.customer_id,
    o.order_id
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
ORDER BY c.customer_id, o.order_id;

-- Reset settings
SET enable_hashjoin = on;
SET enable_nestloop = on;

-- ============================================================================
-- 6. Analyzing aggregation performance
-- ============================================================================
-- Aggregation without index
EXPLAIN ANALYZE
SELECT 
    customer_id,
    COUNT(*) as order_count,
    SUM(total_amount) as total_spent
FROM orders
GROUP BY customer_id;

-- With covering index (index-only scan)
CREATE INDEX IF NOT EXISTS idx_demo_orders_customer_amount 
ON orders(customer_id) INCLUDE (total_amount);

EXPLAIN ANALYZE
SELECT 
    customer_id,
    COUNT(*) as order_count,
    SUM(total_amount) as total_spent
FROM orders
GROUP BY customer_id;

-- ============================================================================
-- 7. Analyzing sorting performance
-- ============================================================================
-- Sort without index
EXPLAIN ANALYZE
SELECT order_id, order_date, total_amount
FROM orders
ORDER BY order_date DESC
LIMIT 10;

-- Check if sort spills to disk (bad for performance)
EXPLAIN (ANALYZE, BUFFERS)
SELECT order_id, order_date, total_amount
FROM orders
ORDER BY order_date DESC;

-- With index (avoids sort operation)
-- Already have idx_orders_date

-- ============================================================================
-- 8. Subquery performance analysis
-- ============================================================================
-- Inefficient: Correlated subquery
EXPLAIN ANALYZE
SELECT 
    c.customer_id,
    c.first_name,
    (SELECT COUNT(*) FROM orders o WHERE o.customer_id = c.customer_id) as order_count
FROM customers c;

-- More efficient: JOIN with GROUP BY
EXPLAIN ANALYZE
SELECT 
    c.customer_id,
    c.first_name,
    COUNT(o.order_id) as order_count
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.first_name;

-- Most efficient: Use pre-computed materialized view
EXPLAIN ANALYZE
SELECT 
    customer_id,
    customer_name,
    total_orders
FROM mv_customer_analytics;

-- ============================================================================
-- 9. CTE vs Subquery performance
-- ============================================================================
-- Using CTE (may be materialized)
EXPLAIN ANALYZE
WITH customer_totals AS (
    SELECT 
        customer_id,
        SUM(total_amount) as total_spent
    FROM orders
    WHERE order_status != 'CANCELLED'
    GROUP BY customer_id
)
SELECT 
    c.customer_id,
    c.first_name,
    ct.total_spent
FROM customers c
JOIN customer_totals ct ON c.customer_id = ct.customer_id
WHERE ct.total_spent > 1000;

-- Using subquery (may be more optimized)
EXPLAIN ANALYZE
SELECT 
    c.customer_id,
    c.first_name,
    order_totals.total_spent
FROM customers c
JOIN (
    SELECT 
        customer_id,
        SUM(total_amount) as total_spent
    FROM orders
    WHERE order_status != 'CANCELLED'
    GROUP BY customer_id
    HAVING SUM(total_amount) > 1000
) order_totals ON c.customer_id = order_totals.customer_id;

-- ============================================================================
-- 10. Identifying missing indexes
-- ============================================================================
-- Query that might benefit from an index
EXPLAIN ANALYZE
SELECT * FROM products WHERE unit_price BETWEEN 100 AND 500;

-- Check if index helps
CREATE INDEX IF NOT EXISTS idx_demo_products_price_range ON products(unit_price);

EXPLAIN ANALYZE
SELECT * FROM products WHERE unit_price BETWEEN 100 AND 500;

-- ============================================================================
-- 11. Function performance in WHERE clause
-- ============================================================================
-- Inefficient: Function prevents index usage
EXPLAIN ANALYZE
SELECT * FROM customers WHERE LOWER(email) = 'john.doe@email.com';

-- More efficient: Use functional index
CREATE INDEX IF NOT EXISTS idx_demo_customers_email_lower ON customers(LOWER(email));

EXPLAIN ANALYZE
SELECT * FROM customers WHERE LOWER(email) = 'john.doe@email.com';

-- ============================================================================
-- 12. Analyzing LIMIT and OFFSET performance
-- ============================================================================
-- LIMIT is efficient
EXPLAIN ANALYZE
SELECT * FROM orders ORDER BY order_date DESC LIMIT 10;

-- Large OFFSET is inefficient (still processes all rows before offset)
EXPLAIN ANALYZE
SELECT * FROM orders ORDER BY order_date DESC LIMIT 10 OFFSET 1000;

-- Better approach: Use keyset pagination
EXPLAIN ANALYZE
SELECT * FROM orders 
WHERE order_date < (SELECT order_date FROM orders ORDER BY order_date DESC LIMIT 1 OFFSET 1000)
ORDER BY order_date DESC 
LIMIT 10;

-- ============================================================================
-- 13. EXISTS vs IN performance
-- ============================================================================
-- Using IN (materializes subquery)
EXPLAIN ANALYZE
SELECT * FROM customers
WHERE customer_id IN (
    SELECT DISTINCT customer_id FROM orders WHERE total_amount > 1000
);

-- Using EXISTS (short-circuits on first match)
EXPLAIN ANALYZE
SELECT * FROM customers c
WHERE EXISTS (
    SELECT 1 FROM orders o 
    WHERE o.customer_id = c.customer_id AND o.total_amount > 1000
);

-- Using JOIN (often most efficient)
EXPLAIN ANALYZE
SELECT DISTINCT c.*
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.total_amount > 1000;

-- ============================================================================
-- 14. Partition pruning analysis
-- ============================================================================
-- If using partitioned tables
EXPLAIN ANALYZE
SELECT * FROM orders_partitioned
WHERE order_date BETWEEN '2024-01-01' AND '2024-03-31';

-- Should show partition pruning in action

-- ============================================================================
-- 15. Parallel query execution
-- ============================================================================
-- Check parallel settings
SHOW max_parallel_workers_per_gather;
SHOW parallel_setup_cost;

-- Query that might use parallel execution
EXPLAIN ANALYZE
SELECT 
    customer_id,
    COUNT(*) as order_count,
    SUM(total_amount) as total_spent
FROM orders
GROUP BY customer_id;

-- Force parallel execution (for testing)
SET parallel_setup_cost = 0;
SET parallel_tuple_cost = 0;

EXPLAIN ANALYZE
SELECT 
    customer_id,
    COUNT(*) as order_count,
    SUM(total_amount) as total_spent
FROM orders
GROUP BY customer_id;

-- Reset
RESET parallel_setup_cost;
RESET parallel_tuple_cost;

-- ============================================================================
-- 16. Query rewriting for better performance
-- ============================================================================
-- SLOW: Multiple subqueries
EXPLAIN ANALYZE
SELECT 
    p.product_id,
    p.product_name,
    (SELECT COUNT(*) FROM order_items oi WHERE oi.product_id = p.product_id) as times_ordered,
    (SELECT AVG(rating) FROM reviews r WHERE r.product_id = p.product_id) as avg_rating
FROM products p
WHERE p.is_active = TRUE;

-- FASTER: Single query with JOINs
EXPLAIN ANALYZE
SELECT 
    p.product_id,
    p.product_name,
    COUNT(DISTINCT oi.order_id) as times_ordered,
    AVG(r.rating) as avg_rating
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
LEFT JOIN reviews r ON p.product_id = r.product_id
WHERE p.is_active = TRUE
GROUP BY p.product_id, p.product_name;

-- ============================================================================
-- 17. Analyzing index-only scans
-- ============================================================================
-- Query that should use index-only scan
EXPLAIN (ANALYZE, BUFFERS)
SELECT customer_id, order_date
FROM orders
WHERE customer_id = 5
ORDER BY order_date;

-- Check heap fetches (should be 0 for true index-only scan)

-- ============================================================================
-- 18. Vacuuming impact on performance
-- ============================================================================
-- Check table bloat
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size,
    n_dead_tup as dead_tuples,
    n_live_tup as live_tuples,
    ROUND(n_dead_tup::numeric / NULLIF(n_live_tup, 0) * 100, 2) as dead_tuple_percent
FROM pg_stat_user_tables
WHERE schemaname = 'public'
ORDER BY n_dead_tup DESC;

-- Vacuum to improve performance
-- VACUUM ANALYZE orders;

-- ============================================================================
-- 19. Statistics and query planner
-- ============================================================================
-- Check table statistics freshness
SELECT 
    schemaname,
    tablename,
    last_vacuum,
    last_autovacuum,
    last_analyze,
    last_autoanalyze,
    n_mod_since_analyze
FROM pg_stat_user_tables
WHERE schemaname = 'public';

-- Update statistics for better query plans
ANALYZE orders;
ANALYZE customers;
ANALYZE products;

-- ============================================================================
-- 20. Cost-based query tuning parameters
-- ============================================================================
-- View current cost settings
SHOW seq_page_cost;      -- Cost of sequential page read
SHOW random_page_cost;   -- Cost of random page read
SHOW cpu_tuple_cost;     -- Cost of processing each row
SHOW cpu_index_tuple_cost; -- Cost of processing each index entry
SHOW cpu_operator_cost;  -- Cost of processing each operator

-- Adjust for SSD (example - don't actually change in production without testing)
-- SET random_page_cost = 1.1;  -- Lower for SSD (default 4)
-- SET seq_page_cost = 1.0;

-- ============================================================================
-- 21. Identifying slow queries
-- ============================================================================
-- Enable slow query logging (requires superuser)
-- ALTER SYSTEM SET log_min_duration_statement = 1000; -- Log queries > 1 second
-- SELECT pg_reload_conf();

-- Query to find slow running queries
SELECT 
    pid,
    usename,
    datname,
    state,
    query,
    now() - query_start AS duration
FROM pg_stat_activity
WHERE state = 'active'
    AND now() - query_start > interval '5 seconds'
ORDER BY duration DESC;

-- ============================================================================
-- 22. Query optimization checklist
-- ============================================================================
/*
QUERY OPTIMIZATION CHECKLIST:

1. Use EXPLAIN ANALYZE to understand query execution
2. Look for sequential scans on large tables - add indexes
3. Ensure foreign keys are indexed
4. Use covering indexes for frequently accessed columns
5. Avoid functions on indexed columns in WHERE clause
6. Use EXISTS instead of IN for large subqueries
7. Replace correlated subqueries with JOINs
8. Use CTEs for readability, but test performance
9. Limit result sets with WHERE before joining
10. Use appropriate JOIN types
11. Consider materialized views for complex aggregations
12. Use LIMIT for paginated results
13. Avoid SELECT * - specify only needed columns
14. Use batch processing for large updates
15. Regular VACUUM and ANALYZE
16. Monitor index usage and remove unused indexes
17. Check for index bloat and REINDEX if needed
18. Use appropriate data types
19. Consider partitioning for very large tables
20. Test with production-like data volumes
*/

-- ============================================================================
-- Summary
-- ============================================================================
COMMENT ON TABLE orders IS 
'This file demonstrates: EXPLAIN and EXPLAIN ANALYZE usage, understanding
query plans, identifying missing indexes, analyzing JOIN types, optimizing
aggregations and sorts, comparing subquery vs JOIN performance, CTE
optimization, parallel query execution, query rewriting techniques,
index-only scans, vacuuming impact, statistics management, cost parameters,
and comprehensive query optimization strategies';


