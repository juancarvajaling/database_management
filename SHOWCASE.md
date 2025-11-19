# Data Storage Competencies

## Selects data from a database using query language

```sql
-- Get customer contact information
SELECT 
    customer_id,
    first_name,
    last_name,
    email,
    phone
FROM customers;

-- Find high-value orders (over $1000)
SELECT 
    order_id,
    customer_id,
    order_date,
    total_amount
FROM orders
WHERE total_amount > 1000.00
ORDER BY total_amount DESC;
```

## Creates and modifies database objects

```sql
-- Creating a new table
CREATE TABLE customer_feedback (
    feedback_id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL,
    feedback_type VARCHAR(50) NOT NULL CHECK (feedback_type IN ('COMPLAINT', 'SUGGESTION', 'COMPLIMENT', 'QUESTION')),
    subject VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    status VARCHAR(20) DEFAULT 'OPEN' CHECK (status IN ('OPEN', 'IN_PROGRESS', 'RESOLVED', 'CLOSED')),
    priority INTEGER DEFAULT 3 CHECK (priority BETWEEN 1 AND 5),
    submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP,
    assigned_to VARCHAR(100),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE CASCADE
);

COMMENT ON TABLE customer_feedback IS 'Customer feedback and support ticket tracking';

-- Alter table - add column
ALTER TABLE customer_feedback
ADD COLUMN response_deadline DATE;

-- Alter table - rename column
ALTER TABLE customer_feedback
RENAME COLUMN response_deadline TO response_deadline_date;

-- Alter table - drop column
ALTER TABLE customer_feedback
DROP COLUMN response_deadline_date;

-- Alter table - rename table
ALTER TABLE customer_feedback
RENAME TO customer_feedback_temp;

-- Alter table - drop table
DROP TABLE customer_feedback_temp;
```

For DML statements see [insert_sample_data.sql](/data/insert_sample_data.sql)

## Orders and groups data from a database using query language

```sql
-- List products by price (lowest to highest)
SELECT 
    product_id,
    product_name,
    unit_price
FROM products
ORDER BY unit_price ASC;

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
```

## Combines multiple queries to optimise query execution

See [04_create_views.sql](/schema/04_create_views.sql)

## Implements and modifies database structure

See [02_create_tables.sql](/schema/02_create_tables.sql)

## Wraps queries into transactions to ensure data consistency and integrity

```sql
BEGIN;

-- Create a new order
INSERT INTO orders (customer_id, shipping_address_id, billing_address_id, order_status, payment_status, payment_method, subtotal, tax_amount, shipping_cost, discount_amount, total_amount)
VALUES (1, 1, 2, 'PENDING', 'PENDING', 'CREDIT_CARD', 100.00, 8.75, 0.00, 0.00, 108.75);

-- Get the order ID
SELECT currval('orders_order_id_seq') as new_order_id;

-- Add order items
INSERT INTO order_items (order_id, product_id, quantity, unit_price, discount_percent, line_total)
VALUES 
    (currval('orders_order_id_seq'), 7, 2, 29.99, 0, 59.98),
    (currval('orders_order_id_seq'), 15, 2, 14.99, 0, 29.98);

-- Verify the data
SELECT * FROM orders WHERE order_id = currval('orders_order_id_seq');
SELECT * FROM order_items WHERE order_id = currval('orders_order_id_seq');

COMMIT;
```

```sql
-- Transaction with rollback
BEGIN;

-- Attempt to create an order with invalid data
INSERT INTO customers (email, first_name, last_name, customer_tier)
VALUES ('test@test.com', 'Test', 'User', 'BRONZE');

-- Get customer ID
SELECT currval('customers_customer_id_seq') as test_customer_id;

ROLLBACK;
```

```sql
BEGIN;

-- Update customer tiers based on spending
UPDATE customers c
SET customer_tier = 
    CASE 
        WHEN order_totals.total >= 10000 THEN 'PLATINUM'
        WHEN order_totals.total >= 5000 THEN 'GOLD'
        WHEN order_totals.total >= 1000 THEN 'SILVER'
        ELSE 'BRONZE'
    END
FROM (
    SELECT 
        customer_id,
        SUM(total_amount) as total
    FROM orders
    WHERE order_status NOT IN ('CANCELLED', 'REFUNDED')
    GROUP BY customer_id
) as order_totals
WHERE c.customer_id = order_totals.customer_id;

-- Log the tier updates
INSERT INTO audit_log (table_name, record_id, action, new_values)
SELECT 
    'customers',
    customer_id,
    'TIER_UPDATE',
    json_build_object('new_tier', customer_tier)::jsonb
FROM customers;

ROLLBACK;
```

## Applies technics for database optimisation

See [03_create_indexes.sql](/schema/03_create_indexes.sql)

- Materialized view
    ```sql
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
    ```

## Documents information about a database using specialised tools

See [documentation](/documentation/) folder.

## Optimises query performance using query techniques and methodologies

- Indexes
- Functions
- Materialized Views
- Multiple queries vs single query with JOIN

- Correlated Subquery vs JOIN
    ```sql
    EXPLAIN ANALYZE
    SELECT 
        c.customer_id,
        c.first_name,
        c.last_name,
        (SELECT COUNT(*) FROM orders o WHERE o.customer_id = c.customer_id) as order_count,
        (SELECT SUM(total_amount) FROM orders o WHERE o.customer_id = c.customer_id) as total_spent
    FROM customers c
    WHERE c.is_active = TRUE;


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
    ```

- Partial Index for Frequent Query Pattern

    ```sql
    DROP INDEX IF EXISTS idx_temp_orders_active_date;
    CREATE INDEX idx_temp_orders_active_date ON orders(order_date);

    EXPLAIN ANALYZE
    SELECT * FROM orders 
    WHERE order_status NOT IN ('CANCELLED', 'REFUNDED')
        AND order_date > '2024-01-01';


    CREATE INDEX idx_temp_orders_active_date ON orders(order_date)
    WHERE order_status NOT IN ('CANCELLED', 'REFUNDED');

    EXPLAIN ANALYZE
    SELECT * FROM orders 
    WHERE order_status NOT IN ('CANCELLED', 'REFUNDED')
        AND order_date > '2024-01-01';
    ```
