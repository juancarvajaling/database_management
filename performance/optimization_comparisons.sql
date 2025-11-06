-- ============================================================================
-- Query Optimization - Before/After Comparisons
-- ============================================================================
-- Competency: Optimises query performance using query techniques and methodologies
-- Description: Side-by-side comparison of query optimization techniques
-- ============================================================================

-- ============================================================================
-- COMPARISON 1: Sequential Scan vs Index Scan
-- ============================================================================

-- BEFORE: No index, sequential scan
DROP INDEX IF EXISTS idx_temp_order_status;

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM orders WHERE order_status = 'DELIVERED';

/*
Expected: Seq Scan on orders
Cost: High
Time: Slow (proportional to table size)
*/

-- AFTER: With index
CREATE INDEX idx_temp_order_status ON orders(order_status);

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM orders WHERE order_status = 'DELIVERED';

/*
Expected: Index Scan or Bitmap Index Scan
Cost: Much lower
Time: Faster (logarithmic to filtered rows)
Improvement: 5-10x faster
*/

-- ============================================================================
-- COMPARISON 2: Correlated Subquery vs JOIN
-- ============================================================================

-- BEFORE: Correlated subquery (runs for each customer)
EXPLAIN ANALYZE
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    (SELECT COUNT(*) FROM orders o WHERE o.customer_id = c.customer_id) as order_count,
    (SELECT SUM(total_amount) FROM orders o WHERE o.customer_id = c.customer_id) as total_spent
FROM customers c
WHERE c.is_active = TRUE;

/*
Problem: Subquery executed N times (once per customer)
Cost: High
Time: O(N * M) where N=customers, M=orders per customer
*/

-- AFTER: JOIN with GROUP BY
EXPLAIN ANALYZE
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    COUNT(o.order_id) as order_count,
    COALESCE(SUM(o.total_amount), 0) as total_spent
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE c.is_active = TRUE
GROUP BY c.customer_id, c.first_name, c.last_name;

/*
Improvement: Single pass through data
Cost: Much lower
Time: O(N + M) linear time
Improvement: 10-100x faster depending on data size
*/

-- ============================================================================
-- COMPARISON 3: SELECT * vs Specific Columns
-- ============================================================================

-- BEFORE: SELECT * pulls all columns
EXPLAIN (ANALYZE, BUFFERS)
SELECT * 
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_date > '2024-01-01';

/*
Problem: Fetches unnecessary data
Network: More data transferred
Memory: More memory used
*/

-- AFTER: Select only needed columns
EXPLAIN (ANALYZE, BUFFERS)
SELECT 
    o.order_id,
    o.order_date,
    o.total_amount,
    c.customer_id,
    c.first_name,
    c.last_name
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_date > '2024-01-01';

/*
Improvement: Less data fetched and transferred
May enable index-only scans
Improvement: 20-50% faster
*/

-- ============================================================================
-- COMPARISON 4: Function on Indexed Column vs Function Index
-- ============================================================================

-- BEFORE: Function prevents index usage
EXPLAIN ANALYZE
SELECT * FROM customers WHERE LOWER(email) = 'john.doe@email.com';

/*
Problem: LOWER() function prevents index on email from being used
Result: Sequential scan
*/

-- AFTER: Create function-based index
CREATE INDEX IF NOT EXISTS idx_customers_email_lower ON customers(LOWER(email));

EXPLAIN ANALYZE
SELECT * FROM customers WHERE LOWER(email) = 'john.doe@email.com';

/*
Improvement: Index can be used
Result: Index scan
Improvement: 100-1000x faster on large tables
*/

-- ============================================================================
-- COMPARISON 5: Multiple Queries vs Single Query with JOIN
-- ============================================================================

-- BEFORE: Multiple round trips to database
/*
-- Query 1
SELECT * FROM customers WHERE customer_id = 5;

-- Query 2
SELECT * FROM orders WHERE customer_id = 5;

-- Query 3
SELECT * FROM addresses WHERE customer_id = 5;
*/

/*
Problem: 3 network round trips
Problem: 3 separate query plans
Cost: High latency
*/

-- AFTER: Single query with JOINs
EXPLAIN ANALYZE
SELECT 
    c.*,
    json_agg(DISTINCT o.*) as orders,
    json_agg(DISTINCT a.*) as addresses
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
LEFT JOIN addresses a ON c.customer_id = a.customer_id
WHERE c.customer_id = 5
GROUP BY c.customer_id;

/*
Improvement: Single network round trip
Improvement: Single query plan
Improvement: 2-5x faster due to reduced latency
*/

-- ============================================================================
-- COMPARISON 6: OFFSET vs Keyset Pagination
-- ============================================================================

-- BEFORE: Traditional OFFSET pagination (inefficient for large offsets)
EXPLAIN ANALYZE
SELECT order_id, order_date, total_amount
FROM orders
ORDER BY order_date DESC
LIMIT 10 OFFSET 10000;

/*
Problem: Must scan and skip 10,000 rows
Cost: Increases linearly with offset
Time: Very slow for large offsets
*/

-- AFTER: Keyset pagination (seeks directly)
EXPLAIN ANALYZE
SELECT order_id, order_date, total_amount
FROM orders
WHERE order_date < '2024-01-15 10:00:00'  -- Last value from previous page
ORDER BY order_date DESC
LIMIT 10;

/*
Improvement: Seeks directly to position using index
Cost: Constant time regardless of page
Improvement: 10-100x faster for deep pagination
*/

-- ============================================================================
-- COMPARISON 7: Regular View vs Materialized View
-- ============================================================================

-- BEFORE: Regular view (computed every time)
CREATE OR REPLACE VIEW v_slow_product_analytics AS
SELECT 
    p.product_id,
    p.product_name,
    COUNT(DISTINCT oi.order_id) as times_ordered,
    SUM(oi.quantity) as total_units_sold,
    SUM(oi.line_total) as total_revenue,
    AVG(r.rating) as avg_rating,
    COUNT(DISTINCT r.review_id) as review_count
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
LEFT JOIN reviews r ON p.product_id = r.product_id
GROUP BY p.product_id, p.product_name;

EXPLAIN ANALYZE
SELECT * FROM v_slow_product_analytics ORDER BY total_revenue DESC LIMIT 10;

/*
Problem: Full computation on every query
Cost: High
Time: Slow (depends on data volume)
*/

-- AFTER: Materialized view (pre-computed)
-- Already created: mv_product_performance

EXPLAIN ANALYZE
SELECT * FROM mv_product_performance ORDER BY total_revenue DESC LIMIT 10;

/*
Improvement: Pre-computed results
Cost: Very low (simple table scan)
Time: Fast (milliseconds)
Trade-off: Needs periodic refresh
Improvement: 100-1000x faster
*/

-- ============================================================================
-- COMPARISON 8: NOT IN vs NOT EXISTS vs LEFT JOIN
-- ============================================================================

-- BEFORE: NOT IN with subquery
EXPLAIN ANALYZE
SELECT * FROM customers
WHERE customer_id NOT IN (
    SELECT customer_id FROM orders WHERE order_status = 'DELIVERED'
);

/*
Problem: Materializes entire subquery
Problem: Slow with NULL values
Cost: High
*/

-- BETTER: NOT EXISTS
EXPLAIN ANALYZE
SELECT * FROM customers c
WHERE NOT EXISTS (
    SELECT 1 FROM orders o 
    WHERE o.customer_id = c.customer_id AND o.order_status = 'DELIVERED'
);

/*
Improvement: Short-circuits on first match
Handles NULLs correctly
*/

-- BEST: LEFT JOIN with NULL check
EXPLAIN ANALYZE
SELECT DISTINCT c.*
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id AND o.order_status = 'DELIVERED'
WHERE o.order_id IS NULL;

/*
Improvement: Usually fastest
Optimizer can use indexes effectively
Improvement: 2-10x faster than NOT IN
*/

-- ============================================================================
-- COMPARISON 9: Implicit vs Explicit JOIN
-- ============================================================================

-- BEFORE: Implicit JOIN (old style, hard to read)
EXPLAIN ANALYZE
SELECT o.order_id, c.first_name, p.product_name
FROM orders o, customers c, order_items oi, products p
WHERE o.customer_id = c.customer_id
    AND o.order_id = oi.order_id
    AND oi.product_id = p.product_id;

/*
Problem: Hard to read and maintain
Problem: Easy to create accidental Cartesian products
*/

-- AFTER: Explicit JOIN (modern style)
EXPLAIN ANALYZE
SELECT o.order_id, c.first_name, p.product_name
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
INNER JOIN order_items oi ON o.order_id = oi.order_id
INNER JOIN products p ON oi.product_id = p.product_id;

/*
Improvement: Clear join conditions
Improvement: Better readability
Improvement: Same performance, better maintainability
*/

-- ============================================================================
-- COMPARISON 10: Aggregation with/without Index
-- ============================================================================

-- BEFORE: Aggregation without covering index
DROP INDEX IF EXISTS idx_temp_orders_customer_amount;

EXPLAIN ANALYZE
SELECT 
    customer_id,
    COUNT(*) as order_count,
    SUM(total_amount) as total_spent
FROM orders
GROUP BY customer_id;

/*
Result: Sequential scan + aggregation
Cost: Must read all rows from heap
*/

-- AFTER: With covering index
CREATE INDEX idx_temp_orders_customer_amount ON orders(customer_id) INCLUDE (total_amount);

EXPLAIN ANALYZE
SELECT 
    customer_id,
    COUNT(*) as order_count,
    SUM(total_amount) as total_spent
FROM orders
GROUP BY customer_id;

/*
Improvement: Index-only scan (no heap access)
Improvement: 2-5x faster
*/

-- ============================================================================
-- COMPARISON 11: Partial Index for Frequent Query Pattern
-- ============================================================================

-- BEFORE: Full index on all rows
DROP INDEX IF EXISTS idx_temp_orders_active_date;
CREATE INDEX idx_temp_orders_active_date ON orders(order_date);

EXPLAIN ANALYZE
SELECT * FROM orders 
WHERE order_status NOT IN ('CANCELLED', 'REFUNDED')
    AND order_date > '2024-01-01';

/*
Index used, but scans cancelled orders too
Index size: Larger (includes all rows)
*/

-- AFTER: Partial index on active orders only
CREATE INDEX idx_temp_orders_active_date ON orders(order_date)
WHERE order_status NOT IN ('CANCELLED', 'REFUNDED');

EXPLAIN ANALYZE
SELECT * FROM orders 
WHERE order_status NOT IN ('CANCELLED', 'REFUNDED')
    AND order_date > '2024-01-01';

/*
Improvement: Smaller index (only active orders)
Improvement: Faster scans
Improvement: Less maintenance overhead
Improvement: 20-40% faster
*/

-- ============================================================================
-- COMPARISON 12: CTE Materialization
-- ============================================================================

-- BEFORE: CTE that's materialized (barrier to optimization)
EXPLAIN ANALYZE
WITH expensive_products AS (
    SELECT * FROM products WHERE unit_price > 100
)
SELECT ep.*, pc.category_name
FROM expensive_products ep
JOIN product_categories pc ON ep.category_id = pc.category_id
WHERE ep.is_active = TRUE;

/*
CTE may be materialized (optimization fence)
Can't push predicates through CTE
*/

-- AFTER: Inline subquery or direct query
EXPLAIN ANALYZE
SELECT p.*, pc.category_name
FROM products p
JOIN product_categories pc ON p.category_id = pc.category_id
WHERE p.unit_price > 100 AND p.is_active = TRUE;

/*
Improvement: Optimizer has full visibility
Can push predicates down
Can reorder joins
May be significantly faster
*/

-- Or use CTE with NOT MATERIALIZED hint (PostgreSQL 12+)
EXPLAIN ANALYZE
WITH expensive_products AS NOT MATERIALIZED (
    SELECT * FROM products WHERE unit_price > 100
)
SELECT ep.*, pc.category_name
FROM expensive_products ep
JOIN product_categories pc ON ep.category_id = pc.category_id
WHERE ep.is_active = TRUE;

-- ============================================================================
-- COMPARISON 13: Transaction Scope
-- ============================================================================

-- BEFORE: Many small transactions
/*
BEGIN;
UPDATE inventory SET quantity_available = quantity_available - 1 WHERE product_id = 1;
COMMIT;

BEGIN;
UPDATE inventory SET quantity_available = quantity_available - 1 WHERE product_id = 2;
COMMIT;

BEGIN;
UPDATE inventory SET quantity_available = quantity_available - 1 WHERE product_id = 3;
COMMIT;
*/

/*
Problem: Transaction overhead multiplied
Problem: Many commit operations
Problem: Lock/unlock overhead
*/

-- AFTER: Batch in single transaction
/*
BEGIN;
UPDATE inventory SET quantity_available = quantity_available - 1 WHERE product_id = 1;
UPDATE inventory SET quantity_available = quantity_available - 1 WHERE product_id = 2;
UPDATE inventory SET quantity_available = quantity_available - 1 WHERE product_id = 3;
COMMIT;
*/

/*
Improvement: Single transaction overhead
Improvement: Single commit
Improvement: 3-10x faster
*/

-- ============================================================================
-- COMPARISON 14: UNION vs UNION ALL
-- ============================================================================

-- BEFORE: UNION (removes duplicates)
EXPLAIN ANALYZE
SELECT product_name, unit_price FROM products WHERE category_id = 1
UNION
SELECT product_name, unit_price FROM products WHERE category_id = 2;

/*
Extra step: Sort and remove duplicates
Cost: Higher
*/

-- AFTER: UNION ALL (keeps duplicates if known to be unique)
EXPLAIN ANALYZE
SELECT product_name, unit_price FROM products WHERE category_id = 1
UNION ALL
SELECT product_name, unit_price FROM products WHERE category_id = 2;

/*
Improvement: No deduplication
Improvement: 2-5x faster
Use when: Results are naturally unique or duplicates acceptable
*/

-- ============================================================================
-- PERFORMANCE GAINS SUMMARY
-- ============================================================================
/*
Optimization Technique                          | Performance Gain
------------------------------------------------|------------------
Sequential Scan → Index Scan                    | 5-10x
Correlated Subquery → JOIN                      | 10-100x
SELECT * → Specific Columns                     | 1.2-1.5x
Regular View → Materialized View                | 100-1000x
Function on Column → Function Index             | 100-1000x
Large OFFSET → Keyset Pagination                | 10-100x
NOT IN → NOT EXISTS / LEFT JOIN                 | 2-10x
Multiple Queries → Single JOIN                  | 2-5x
Full Index → Partial Index                      | 1.2-1.4x
Many Transactions → Batch Transaction           | 3-10x
UNION → UNION ALL                              | 2-5x
Regular Index → Covering Index                  | 2-5x
Implicit JOIN → Explicit JOIN                   | Same (readability)
CTE Materialized → Inline/NOT MATERIALIZED      | 1.5-3x

GENERAL RULES:
1. Add indexes for WHERE, JOIN, ORDER BY columns
2. Use JOINs instead of subqueries when possible
3. Select only needed columns
4. Use materialized views for complex aggregations
5. Batch operations when possible
6. Use appropriate index types (B-tree, GIN, BRIN)
7. Keep statistics up to date (ANALYZE)
8. Monitor with EXPLAIN ANALYZE
9. Consider partitioning for very large tables
10. Use connection pooling in applications
*/

-- ============================================================================
-- Clean up temporary indexes
-- ============================================================================
DROP INDEX IF EXISTS idx_temp_order_status;
DROP INDEX IF EXISTS idx_temp_orders_customer_amount;
DROP INDEX IF EXISTS idx_temp_orders_active_date;
DROP VIEW IF EXISTS v_slow_product_analytics;

-- ============================================================================
-- Summary
-- ============================================================================
COMMENT ON TABLE orders IS 
'This file demonstrates side-by-side performance comparisons showing:
before/after optimization scenarios, query rewriting techniques, index strategies,
JOIN optimization, pagination techniques, view vs materialized view performance,
transaction batching, and comprehensive performance gain metrics for each optimization';


