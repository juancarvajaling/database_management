-- ============================================================================
-- Table Partitioning for Performance Optimization
-- ============================================================================
-- Competency: Applies technics for database optimisation
-- Description: Demonstrates table partitioning strategies for large datasets
-- ============================================================================

-- ============================================================================
-- 1. Range Partitioning by Date - Most common use case
-- ============================================================================
-- Create partitioned orders table (for demonstration)
CREATE TABLE orders_partitioned (
    order_id SERIAL,
    customer_id INTEGER NOT NULL,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    shipping_address_id INTEGER NOT NULL,
    billing_address_id INTEGER NOT NULL,
    order_status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    payment_status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    payment_method VARCHAR(50),
    subtotal DECIMAL(10, 2) NOT NULL,
    tax_amount DECIMAL(10, 2) NOT NULL DEFAULT 0,
    shipping_cost DECIMAL(10, 2) NOT NULL DEFAULT 0,
    discount_amount DECIMAL(10, 2) NOT NULL DEFAULT 0,
    total_amount DECIMAL(10, 2) NOT NULL,
    shipped_at TIMESTAMP,
    delivered_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) PARTITION BY RANGE (order_date);

-- Create partitions for each quarter
CREATE TABLE orders_2024_q1 PARTITION OF orders_partitioned
    FOR VALUES FROM ('2024-01-01') TO ('2024-04-01');

CREATE TABLE orders_2024_q2 PARTITION OF orders_partitioned
    FOR VALUES FROM ('2024-04-01') TO ('2024-07-01');

CREATE TABLE orders_2024_q3 PARTITION OF orders_partitioned
    FOR VALUES FROM ('2024-07-01') TO ('2024-10-01');

CREATE TABLE orders_2024_q4 PARTITION OF orders_partitioned
    FOR VALUES FROM ('2024-10-01') TO ('2025-01-01');

CREATE TABLE orders_2025_q1 PARTITION OF orders_partitioned
    FOR VALUES FROM ('2025-01-01') TO ('2025-04-01');

-- Create default partition for out-of-range values
CREATE TABLE orders_default PARTITION OF orders_partitioned DEFAULT;

COMMENT ON TABLE orders_partitioned IS 'Range-partitioned orders table by quarter for improved query performance';

-- ============================================================================
-- 2. Create indexes on partitioned table
-- ============================================================================
-- Indexes are created on each partition automatically
CREATE INDEX idx_orders_part_customer ON orders_partitioned(customer_id);
CREATE INDEX idx_orders_part_status ON orders_partitioned(order_status);
CREATE INDEX idx_orders_part_date ON orders_partitioned(order_date);

-- ============================================================================
-- 3. Insert data into partitioned table
-- ============================================================================
-- Data automatically routed to correct partition
INSERT INTO orders_partitioned 
SELECT * FROM orders;

-- ============================================================================
-- 4. Query partitioned table - Partition pruning
-- ============================================================================
-- Query automatically uses only relevant partitions
EXPLAIN ANALYZE
SELECT * FROM orders_partitioned
WHERE order_date BETWEEN '2024-01-01' AND '2024-03-31';

-- This query scans only the 2024-Q1 partition, not all partitions

-- ============================================================================
-- 5. List Partitioning - By category or status
-- ============================================================================
-- Create list-partitioned table for customer data
CREATE TABLE customers_partitioned (
    customer_id SERIAL,
    email VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    date_of_birth DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    customer_tier VARCHAR(20) DEFAULT 'BRONZE'
) PARTITION BY LIST (customer_tier);

-- Create partition for each tier
CREATE TABLE customers_bronze PARTITION OF customers_partitioned
    FOR VALUES IN ('BRONZE');

CREATE TABLE customers_silver PARTITION OF customers_partitioned
    FOR VALUES IN ('SILVER');

CREATE TABLE customers_gold PARTITION OF customers_partitioned
    FOR VALUES IN ('GOLD');

CREATE TABLE customers_platinum PARTITION OF customers_partitioned
    FOR VALUES IN ('PLATINUM');

COMMENT ON TABLE customers_partitioned IS 'List-partitioned customers by tier';

-- Insert data
INSERT INTO customers_partitioned 
SELECT * FROM customers;

-- Query specific partition
EXPLAIN ANALYZE
SELECT * FROM customers_partitioned
WHERE customer_tier = 'PLATINUM';

-- ============================================================================
-- 6. Hash Partitioning - For even distribution
-- ============================================================================
-- Create hash-partitioned table for even load distribution
CREATE TABLE products_partitioned (
    product_id SERIAL,
    product_name VARCHAR(255) NOT NULL,
    category_id INTEGER NOT NULL,
    sku VARCHAR(50) NOT NULL,
    description TEXT,
    unit_price DECIMAL(10, 2) NOT NULL,
    cost_price DECIMAL(10, 2) NOT NULL,
    weight_kg DECIMAL(8, 2),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) PARTITION BY HASH (product_id);

-- Create hash partitions (4 partitions for even distribution)
CREATE TABLE products_part_0 PARTITION OF products_partitioned
    FOR VALUES WITH (MODULUS 4, REMAINDER 0);

CREATE TABLE products_part_1 PARTITION OF products_partitioned
    FOR VALUES WITH (MODULUS 4, REMAINDER 1);

CREATE TABLE products_part_2 PARTITION OF products_partitioned
    FOR VALUES WITH (MODULUS 4, REMAINDER 2);

CREATE TABLE products_part_3 PARTITION OF products_partitioned
    FOR VALUES WITH (MODULUS 4, REMAINDER 3);

COMMENT ON TABLE products_partitioned IS 'Hash-partitioned products for even distribution';

-- Insert data
INSERT INTO products_partitioned 
SELECT * FROM products;

-- ============================================================================
-- 7. Subpartitioning - Multi-level partitioning
-- ============================================================================
-- Create table partitioned by date, then by status
CREATE TABLE orders_subpartitioned (
    order_id SERIAL,
    customer_id INTEGER NOT NULL,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    order_status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    total_amount DECIMAL(10, 2) NOT NULL
) PARTITION BY RANGE (order_date);

-- Create year partition
CREATE TABLE orders_2024 PARTITION OF orders_subpartitioned
    FOR VALUES FROM ('2024-01-01') TO ('2025-01-01')
    PARTITION BY LIST (order_status);

-- Create status subpartitions within 2024
CREATE TABLE orders_2024_active PARTITION OF orders_2024
    FOR VALUES IN ('PENDING', 'CONFIRMED', 'PROCESSING', 'SHIPPED');

CREATE TABLE orders_2024_completed PARTITION OF orders_2024
    FOR VALUES IN ('DELIVERED');

CREATE TABLE orders_2024_cancelled PARTITION OF orders_2024
    FOR VALUES IN ('CANCELLED', 'REFUNDED');

COMMENT ON TABLE orders_subpartitioned IS 'Multi-level partitioning: by date then by status';

-- ============================================================================
-- 8. Partition maintenance - Adding new partitions
-- ============================================================================
-- Add new quarter partition
CREATE TABLE orders_2025_q2 PARTITION OF orders_partitioned
    FOR VALUES FROM ('2025-04-01') TO ('2025-07-01');

-- ============================================================================
-- 9. Partition maintenance - Detaching partitions
-- ============================================================================
-- Detach old partition (for archiving)
-- ALTER TABLE orders_partitioned DETACH PARTITION orders_2024_q1;

-- Now orders_2024_q1 exists as standalone table
-- Can be archived, backed up, or dropped

-- ============================================================================
-- 10. Partition maintenance - Attaching partitions
-- ============================================================================
-- Create standalone table with same structure
CREATE TABLE orders_archive (LIKE orders_partitioned INCLUDING ALL);

-- Attach as partition
-- ALTER TABLE orders_partitioned ATTACH PARTITION orders_archive
--     FOR VALUES FROM ('2023-01-01') TO ('2024-01-01');

-- ============================================================================
-- 11. Partition pruning demonstration
-- ============================================================================
-- Query with partition pruning (scans only relevant partitions)
EXPLAIN (ANALYZE, BUFFERS)
SELECT COUNT(*), SUM(total_amount)
FROM orders_partitioned
WHERE order_date BETWEEN '2024-01-01' AND '2024-03-31';

-- Query without partition key (scans all partitions)
EXPLAIN (ANALYZE, BUFFERS)
SELECT COUNT(*)
FROM orders_partitioned
WHERE customer_id = 5;

-- ============================================================================
-- 12. Analyzing partitioned tables
-- ============================================================================
-- Analyze parent table (analyzes all partitions)
ANALYZE orders_partitioned;

-- Analyze specific partition
ANALYZE orders_2024_q1;

-- ============================================================================
-- 13. View partition information
-- ============================================================================
-- List all partitions
SELECT 
    nmsp_parent.nspname AS parent_schema,
    parent.relname AS parent_table,
    nmsp_child.nspname AS child_schema,
    child.relname AS child_table,
    pg_get_expr(child.relpartbound, child.oid) AS partition_expression
FROM pg_inherits
JOIN pg_class parent ON pg_inherits.inhparent = parent.oid
JOIN pg_class child ON pg_inherits.inhrelid = child.oid
JOIN pg_namespace nmsp_parent ON nmsp_parent.oid = parent.relnamespace
JOIN pg_namespace nmsp_child ON nmsp_child.oid = child.relnamespace
WHERE parent.relname IN ('orders_partitioned', 'customers_partitioned', 'products_partitioned')
ORDER BY parent.relname, child.relname;

-- ============================================================================
-- 14. Partition sizes
-- ============================================================================
-- Check size of each partition
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE tablename LIKE 'orders_2024%'
    OR tablename LIKE 'customers_%'
    OR tablename LIKE 'products_part%'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- ============================================================================
-- 15. Performance comparison - Partitioned vs Non-partitioned
-- ============================================================================
-- Query on non-partitioned table
EXPLAIN ANALYZE
SELECT COUNT(*), SUM(total_amount)
FROM orders
WHERE order_date BETWEEN '2024-01-01' AND '2024-03-31';

-- Same query on partitioned table (should be faster)
EXPLAIN ANALYZE
SELECT COUNT(*), SUM(total_amount)
FROM orders_partitioned
WHERE order_date BETWEEN '2024-01-01' AND '2024-03-31';

-- ============================================================================
-- 16. Partition-wise joins
-- ============================================================================
-- Enable partition-wise join
SET enable_partitionwise_join = on;

-- Join partitioned tables
EXPLAIN ANALYZE
SELECT 
    o.order_id,
    o.order_date,
    c.customer_tier,
    o.total_amount
FROM orders_partitioned o
JOIN customers_partitioned c ON o.customer_id = c.customer_id
WHERE o.order_date BETWEEN '2024-01-01' AND '2024-03-31';

-- ============================================================================
-- 17. Constraint exclusion for older PostgreSQL versions
-- ============================================================================
-- Ensure constraint exclusion is enabled
SHOW constraint_exclusion;
-- SET constraint_exclusion = partition;

-- ============================================================================
-- 18. Automated partition creation function
-- ============================================================================
-- Function to automatically create future partitions
CREATE OR REPLACE FUNCTION create_quarterly_partitions(
    p_table_name TEXT,
    p_start_date DATE,
    p_num_quarters INTEGER
)
RETURNS void AS $$
DECLARE
    v_partition_name TEXT;
    v_start_date DATE;
    v_end_date DATE;
    v_year INTEGER;
    v_quarter INTEGER;
BEGIN
    FOR i IN 0..(p_num_quarters - 1) LOOP
        v_start_date := p_start_date + (i || ' months')::INTERVAL * 3;
        v_end_date := v_start_date + INTERVAL '3 months';
        v_year := EXTRACT(YEAR FROM v_start_date);
        v_quarter := EXTRACT(QUARTER FROM v_start_date);
        
        v_partition_name := p_table_name || '_' || v_year || '_q' || v_quarter;
        
        EXECUTE format(
            'CREATE TABLE IF NOT EXISTS %I PARTITION OF %I FOR VALUES FROM (%L) TO (%L)',
            v_partition_name,
            p_table_name,
            v_start_date,
            v_end_date
        );
        
        RAISE NOTICE 'Created partition: %', v_partition_name;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Use the function to create partitions for next year
-- SELECT create_quarterly_partitions('orders_partitioned', '2026-01-01', 4);

-- ============================================================================
-- 19. Partition pruning with different operators
-- ============================================================================
-- Equality (uses single partition)
EXPLAIN SELECT * FROM orders_partitioned WHERE order_date = '2024-02-15';

-- Range (uses subset of partitions)
EXPLAIN SELECT * FROM orders_partitioned 
WHERE order_date BETWEEN '2024-01-01' AND '2024-06-30';

-- Greater than (uses subset)
EXPLAIN SELECT * FROM orders_partitioned WHERE order_date > '2024-06-01';

-- IN clause (uses matching partitions)
EXPLAIN SELECT * FROM orders_partitioned 
WHERE order_date IN ('2024-01-15', '2024-04-15', '2024-07-15');

-- ============================================================================
-- 20. Partitioning best practices summary
-- ============================================================================
/*
PARTITIONING BEST PRACTICES:

1. Partition large tables (>10GB typically)
2. Use RANGE partitioning for time-series data
3. Use LIST partitioning for categorical data
4. Use HASH partitioning for even distribution
5. Keep partition size reasonable (10-100GB)
6. Partition key should be in most queries
7. Create indexes on partitions, not just parent
8. Regularly maintain partitions (ANALYZE)
9. Automate partition creation/archival
10. Monitor partition sizes and query patterns
11. Consider partition pruning in query design
12. Use constraint exclusion for optimization
13. Archive or drop old partitions
14. Test query performance before/after partitioning
15. Document partition strategy and maintenance schedule

WHEN TO USE PARTITIONING:
- Very large tables (millions+ rows)
- Time-series data with range queries
- Regular archival requirements
- Need to improve query performance on date ranges
- Want to parallelize maintenance operations

WHEN NOT TO USE PARTITIONING:
- Small tables (<10GB)
- Queries don't filter on partition key
- Write-heavy workloads with many partitions
- Simple table structures with good indexes
*/

-- ============================================================================
-- Clean up demonstration tables (optional)
-- ============================================================================
-- DROP TABLE IF EXISTS orders_partitioned CASCADE;
-- DROP TABLE IF EXISTS customers_partitioned CASCADE;
-- DROP TABLE IF EXISTS products_partitioned CASCADE;
-- DROP TABLE IF EXISTS orders_subpartitioned CASCADE;
-- DROP FUNCTION IF EXISTS create_quarterly_partitions(TEXT, DATE, INTEGER);

-- ============================================================================
-- Summary
-- ============================================================================
COMMENT ON TABLE orders_partitioned IS 
'This file demonstrates: Range partitioning by date, list partitioning by category,
hash partitioning for distribution, subpartitioning (multi-level), partition
maintenance (add/detach/attach), partition pruning, performance analysis,
automated partition creation, and partitioning best practices';


