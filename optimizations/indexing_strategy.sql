-- ============================================================================
-- Indexing Strategy and Optimization
-- ============================================================================
-- Competency: Applies technics for database optimisation
-- Description: Demonstrates index types, strategies, and performance impact
-- ============================================================================

-- ============================================================================
-- 1. B-Tree Index (default) - Best for equality and range queries
-- ============================================================================
-- Create standard B-tree index
CREATE INDEX idx_orders_customer_btree ON orders(customer_id);

-- Analyze performance
EXPLAIN ANALYZE
SELECT * FROM orders WHERE customer_id = 5;

-- ============================================================================
-- 2. Composite/Multi-column Index
-- ============================================================================
-- Index on multiple columns for queries filtering both
CREATE INDEX idx_orders_customer_status ON orders(customer_id, order_status);

-- This index helps queries like:
EXPLAIN ANALYZE
SELECT * FROM orders 
WHERE customer_id = 5 AND order_status = 'DELIVERED';

-- Also helps queries on just the first column (customer_id)
EXPLAIN ANALYZE
SELECT * FROM orders WHERE customer_id = 5;

-- But NOT on just the second column alone
EXPLAIN ANALYZE
SELECT * FROM orders WHERE order_status = 'DELIVERED';

-- ============================================================================
-- 3. Partial Index - Index only a subset of rows
-- ============================================================================
-- Index only active orders (saves space and improves performance)
CREATE INDEX idx_orders_active ON orders(order_date, total_amount)
WHERE order_status NOT IN ('CANCELLED', 'REFUNDED');

-- This query will use the partial index
EXPLAIN ANALYZE
SELECT * FROM orders 
WHERE order_status = 'DELIVERED' 
    AND order_date > '2024-01-01'
ORDER BY total_amount DESC;

COMMENT ON INDEX idx_orders_active IS 'Partial index excluding cancelled/refunded orders';

-- ============================================================================
-- 4. Expression/Functional Index
-- ============================================================================
-- Index on computed values
CREATE INDEX idx_customers_email_lower ON customers(LOWER(email));

-- Helps case-insensitive searches
EXPLAIN ANALYZE
SELECT * FROM customers WHERE LOWER(email) = 'john.doe@email.com';

-- Index on date extraction
CREATE INDEX idx_orders_year_month ON orders(EXTRACT(YEAR FROM order_date), EXTRACT(MONTH FROM order_date));

-- Helps date-based grouping
EXPLAIN ANALYZE
SELECT 
    EXTRACT(YEAR FROM order_date) as year,
    EXTRACT(MONTH FROM order_date) as month,
    COUNT(*) 
FROM orders 
GROUP BY EXTRACT(YEAR FROM order_date), EXTRACT(MONTH FROM order_date);

-- ============================================================================
-- 5. Unique Index - Enforces uniqueness
-- ============================================================================
-- Ensure email uniqueness (already exists, but showing principle)
CREATE UNIQUE INDEX idx_unique_customer_email ON customers(email);

-- Composite unique index
CREATE UNIQUE INDEX idx_unique_product_warehouse 
ON inventory(product_id, warehouse_location);

-- ============================================================================
-- 6. GIN Index - For full-text search and array columns
-- ============================================================================
-- Full-text search on product descriptions
CREATE INDEX idx_products_fulltext ON products 
USING gin(to_tsvector('english', product_name || ' ' || COALESCE(description, '')));

-- Use the full-text index
EXPLAIN ANALYZE
SELECT product_id, product_name, description
FROM products
WHERE to_tsvector('english', product_name || ' ' || COALESCE(description, '')) 
    @@ to_tsquery('english', 'laptop | computer');

COMMENT ON INDEX idx_products_fulltext IS 'Full-text search index for product discovery';

-- ============================================================================
-- 7. BRIN Index - For large tables with naturally ordered data
-- ============================================================================
-- Efficient for large tables with correlation to physical storage
CREATE INDEX idx_orders_date_brin ON orders USING brin(order_date);

-- Good for range queries on large tables
EXPLAIN ANALYZE
SELECT COUNT(*), SUM(total_amount)
FROM orders
WHERE order_date BETWEEN '2024-01-01' AND '2024-03-31';

COMMENT ON INDEX idx_orders_date_brin IS 'BRIN index efficient for time-series data';

-- ============================================================================
-- 8. Covering Index - Include extra columns
-- ============================================================================
-- Index includes frequently queried columns
CREATE INDEX idx_orders_customer_covering ON orders(customer_id) 
INCLUDE (order_date, total_amount, order_status);

-- Query can be answered entirely from the index (index-only scan)
EXPLAIN ANALYZE
SELECT customer_id, order_date, total_amount, order_status
FROM orders
WHERE customer_id = 5;

COMMENT ON INDEX idx_orders_customer_covering IS 'Covering index includes commonly queried columns for index-only scans';

-- ============================================================================
-- 9. Index for sorting optimization
-- ============================================================================
-- Index to optimize ORDER BY queries
CREATE INDEX idx_products_price_desc ON products(unit_price DESC);

-- Efficient retrieval of sorted results
EXPLAIN ANALYZE
SELECT product_id, product_name, unit_price
FROM products
WHERE is_active = TRUE
ORDER BY unit_price DESC
LIMIT 10;

-- ============================================================================
-- 10. Index usage analysis
-- ============================================================================
-- Check which indexes are actually being used
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan as number_of_scans,
    idx_tup_read as tuples_read,
    idx_tup_fetch as tuples_fetched
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY idx_scan DESC;

-- Find unused indexes (candidates for removal)
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
    AND idx_scan = 0
    AND indexname NOT LIKE '%_pkey'
ORDER BY tablename, indexname;

-- ============================================================================
-- 11. Index size analysis
-- ============================================================================
-- Check index sizes to identify bloat
SELECT 
    schemaname,
    tablename,
    indexname,
    pg_size_pretty(pg_relation_size(indexrelid)) as index_size
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY pg_relation_size(indexrelid) DESC;

-- ============================================================================
-- 12. Index maintenance - REINDEX
-- ============================================================================
-- Rebuild a bloated or corrupted index
-- REINDEX INDEX idx_orders_customer_btree;

-- Rebuild all indexes on a table
-- REINDEX TABLE orders;

-- Rebuild all indexes in schema
-- REINDEX SCHEMA public;

-- ============================================================================
-- 13. Index selectivity analysis
-- ============================================================================
-- High selectivity = good candidate for indexing
SELECT 
    'customer_tier' as column_name,
    COUNT(DISTINCT customer_tier)::float / COUNT(*) as selectivity,
    COUNT(DISTINCT customer_tier) as unique_values,
    COUNT(*) as total_rows
FROM customers

UNION ALL

SELECT 
    'order_status',
    COUNT(DISTINCT order_status)::float / COUNT(*),
    COUNT(DISTINCT order_status),
    COUNT(*)
FROM orders;

-- ============================================================================
-- 14. Demonstrating index vs no index performance
-- ============================================================================
-- Drop index temporarily to show performance difference
DROP INDEX IF EXISTS idx_test_performance;

-- Query without index
EXPLAIN ANALYZE
SELECT * FROM orders WHERE customer_id = 5;

-- Create index
CREATE INDEX idx_test_performance ON orders(customer_id);

-- Same query with index
EXPLAIN ANALYZE
SELECT * FROM orders WHERE customer_id = 5;

-- ============================================================================
-- 15. Index on foreign keys
-- ============================================================================
-- Always index foreign keys for join performance
CREATE INDEX IF NOT EXISTS idx_order_items_order ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_product ON order_items(product_id);
CREATE INDEX IF NOT EXISTS idx_reviews_product ON reviews(product_id);
CREATE INDEX IF NOT EXISTS idx_reviews_customer ON reviews(customer_id);

-- ============================================================================
-- 16. Index for text pattern matching
-- ============================================================================
-- For LIKE queries with leading wildcard
CREATE INDEX idx_customers_name_pattern ON customers(last_name text_pattern_ops);

-- Helps queries like:
EXPLAIN ANALYZE
SELECT * FROM customers WHERE last_name LIKE 'Sm%';

-- ============================================================================
-- 17. Conditional index based on business logic
-- ============================================================================
-- Index high-value orders only
CREATE INDEX idx_orders_high_value ON orders(order_date, total_amount)
WHERE total_amount > 500;

-- Index low stock items
CREATE INDEX idx_inventory_low_stock_items ON inventory(product_id, quantity_available)
WHERE quantity_available <= reorder_level;

EXPLAIN ANALYZE
SELECT p.product_name, i.quantity_available, i.reorder_level
FROM inventory i
JOIN products p ON i.product_id = p.product_id
WHERE i.quantity_available <= i.reorder_level;

-- ============================================================================
-- 18. Index recommendations based on query patterns
-- ============================================================================
/*
Common Query Pattern 1: Customer order history
*/
CREATE INDEX idx_orders_customer_date_desc ON orders(customer_id, order_date DESC);

/*
Common Query Pattern 2: Product sales analysis
*/
CREATE INDEX idx_order_items_product_order ON order_items(product_id, order_id);

/*
Common Query Pattern 3: Recent orders dashboard
*/
CREATE INDEX idx_orders_recent_status ON orders(order_date DESC, order_status)
WHERE order_status NOT IN ('CANCELLED', 'REFUNDED');

-- ============================================================================
-- 19. Index bloat detection
-- ============================================================================
-- Query to detect index bloat
SELECT 
    schemaname,
    tablename,
    indexname,
    pg_size_pretty(pg_relation_size(indexrelid)) as index_size,
    idx_scan,
    CASE 
        WHEN idx_scan = 0 THEN 'Unused - Consider dropping'
        WHEN idx_scan < 100 THEN 'Rarely used'
        ELSE 'Actively used'
    END as usage_category
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY pg_relation_size(indexrelid) DESC;

-- ============================================================================
-- 20. Index maintenance schedule recommendations
-- ============================================================================
/*
REGULAR MAINTENANCE TASKS:

1. ANALYZE tables after significant data changes
   - Updates statistics for query planner
   - Run: ANALYZE table_name;

2. VACUUM to reclaim space
   - Run: VACUUM ANALYZE table_name;

3. REINDEX periodically for heavily updated indexes
   - Run: REINDEX TABLE table_name;

4. Monitor index usage
   - Query pg_stat_user_indexes regularly
   - Drop unused indexes

5. Check for missing indexes
   - Review slow query logs
   - Analyze EXPLAIN plans
*/

-- Update statistics
ANALYZE customers;
ANALYZE orders;
ANALYZE order_items;
ANALYZE products;

-- ============================================================================
-- Best Practices Summary
-- ============================================================================
/*
INDEX BEST PRACTICES:

1. Index columns used in WHERE, JOIN, and ORDER BY clauses
2. Consider composite indexes for multi-column queries
3. Use partial indexes to reduce index size
4. Index foreign key columns
5. Don't over-index - each index has maintenance cost
6. Monitor index usage and remove unused indexes
7. Use covering indexes for frequently accessed column combinations
8. Consider index selectivity - low selectivity may not benefit from index
9. Use appropriate index type (B-tree, GIN, BRIN, etc.)
10. Regularly maintain indexes with VACUUM and REINDEX
11. Test query performance with EXPLAIN ANALYZE
12. Balance read performance vs. write performance
13. Use expression indexes for computed columns
14. Implement indexes after loading large datasets
15. Document why each index exists
*/

-- ============================================================================
-- Summary
-- ============================================================================
COMMENT ON TABLE orders IS 
'This file demonstrates: B-tree indexes, composite indexes, partial indexes,
expression/functional indexes, unique indexes, GIN indexes for full-text search,
BRIN indexes for large tables, covering indexes, index usage analysis,
index size monitoring, index maintenance (REINDEX), selectivity analysis,
performance comparison, and index best practices';


