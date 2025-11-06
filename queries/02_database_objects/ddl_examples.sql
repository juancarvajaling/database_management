-- ============================================================================
-- Database Object Modification Examples
-- ============================================================================
-- Competency: Creates and modifies database objects
-- Description: Demonstrates CREATE, ALTER, DROP for various database objects
-- ============================================================================

-- ============================================================================
-- 1. Creating a new table
-- ============================================================================
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

-- ============================================================================
-- 2. ALTER TABLE - Add column
-- ============================================================================
ALTER TABLE products 
ADD COLUMN discontinued_date TIMESTAMP;

ALTER TABLE products
ADD COLUMN supplier_id INTEGER;

COMMENT ON COLUMN products.discontinued_date IS 'Date when product was discontinued';

-- ============================================================================
-- 3. ALTER TABLE - Modify column
-- ============================================================================
ALTER TABLE products
ALTER COLUMN description TYPE TEXT;

ALTER TABLE customers
ALTER COLUMN phone TYPE VARCHAR(30);

-- ============================================================================
-- 4. ALTER TABLE - Add constraint
-- ============================================================================
ALTER TABLE products
ADD CONSTRAINT check_discontinued 
    CHECK (discontinued_date IS NULL OR discontinued_date > created_at);

-- ============================================================================
-- 5. ALTER TABLE - Drop column
-- ============================================================================
-- First, let's add a temporary column to demonstrate dropping
ALTER TABLE customer_feedback
ADD COLUMN temp_field VARCHAR(50);

-- Now drop it
ALTER TABLE customer_feedback
DROP COLUMN temp_field;

-- ============================================================================
-- 6. ALTER TABLE - Rename column
-- ============================================================================
ALTER TABLE customer_feedback
RENAME COLUMN message TO feedback_message;

-- Rename it back for consistency
ALTER TABLE customer_feedback
RENAME COLUMN feedback_message TO message;

-- ============================================================================
-- 7. ALTER TABLE - Rename table
-- ============================================================================
CREATE TABLE temp_table (
    id SERIAL PRIMARY KEY,
    data VARCHAR(100)
);

ALTER TABLE temp_table
RENAME TO renamed_temp_table;

-- ============================================================================
-- 8. Creating an index
-- ============================================================================
CREATE INDEX idx_feedback_customer ON customer_feedback(customer_id);
CREATE INDEX idx_feedback_status ON customer_feedback(status, priority);
CREATE INDEX idx_feedback_submitted ON customer_feedback(submitted_at DESC);

-- ============================================================================
-- 9. Creating a unique index
-- ============================================================================
CREATE UNIQUE INDEX idx_renamed_temp_data ON renamed_temp_table(data);

-- ============================================================================
-- 10. Creating a partial index
-- ============================================================================
CREATE INDEX idx_feedback_open ON customer_feedback(priority)
WHERE status = 'OPEN';

COMMENT ON INDEX idx_feedback_open IS 'Partial index for open feedback items';

-- ============================================================================
-- 11. DROP INDEX
-- ============================================================================
-- Create an index to demonstrate dropping
CREATE INDEX idx_temp_example ON customer_feedback(assigned_to);

-- Drop it
DROP INDEX idx_temp_example;

-- ============================================================================
-- 12. Creating a view
-- ============================================================================
CREATE OR REPLACE VIEW v_customer_feedback_summary AS
SELECT 
    c.customer_id,
    c.first_name || ' ' || c.last_name as customer_name,
    c.email,
    COUNT(cf.feedback_id) as total_feedback,
    SUM(CASE WHEN cf.feedback_type = 'COMPLAINT' THEN 1 ELSE 0 END) as complaints,
    SUM(CASE WHEN cf.feedback_type = 'COMPLIMENT' THEN 1 ELSE 0 END) as compliments,
    SUM(CASE WHEN cf.status = 'OPEN' THEN 1 ELSE 0 END) as open_items,
    MAX(cf.submitted_at) as last_feedback_date
FROM customers c
LEFT JOIN customer_feedback cf ON c.customer_id = cf.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name, c.email;

-- ============================================================================
-- 13. Creating a materialized view
-- ============================================================================
CREATE MATERIALIZED VIEW mv_daily_sales_summary AS
SELECT 
    DATE(order_date) as sale_date,
    COUNT(DISTINCT order_id) as order_count,
    COUNT(DISTINCT customer_id) as unique_customers,
    SUM(total_amount) as daily_revenue,
    AVG(total_amount) as avg_order_value,
    SUM(discount_amount) as total_discounts
FROM orders
WHERE order_status NOT IN ('CANCELLED', 'REFUNDED')
GROUP BY DATE(order_date)
WITH DATA;

CREATE INDEX idx_mv_daily_sales_date ON mv_daily_sales_summary(sale_date);

COMMENT ON MATERIALIZED VIEW mv_daily_sales_summary IS 'Pre-computed daily sales metrics for fast reporting';

-- ============================================================================
-- 14. Refresh materialized view
-- ============================================================================
REFRESH MATERIALIZED VIEW mv_daily_sales_summary;

-- ============================================================================
-- 15. DROP VIEW
-- ============================================================================
-- Create a temporary view to demonstrate dropping
CREATE VIEW v_temp_example AS
SELECT * FROM customers WHERE customer_tier = 'PLATINUM';

-- Drop it
DROP VIEW v_temp_example;

-- ============================================================================
-- 16. Creating a sequence
-- ============================================================================
CREATE SEQUENCE invoice_number_seq
    START WITH 1000
    INCREMENT BY 1
    MINVALUE 1000
    MAXVALUE 999999
    CACHE 20;

-- ============================================================================
-- 17. Using a sequence
-- ============================================================================
SELECT nextval('invoice_number_seq');
SELECT currval('invoice_number_seq');
SELECT setval('invoice_number_seq', 1500);

-- ============================================================================
-- 18. ALTER SEQUENCE
-- ============================================================================
ALTER SEQUENCE invoice_number_seq RESTART WITH 2000;
ALTER SEQUENCE invoice_number_seq INCREMENT BY 2;

-- ============================================================================
-- 19. Creating a custom type (ENUM)
-- ============================================================================
CREATE TYPE order_priority AS ENUM ('LOW', 'MEDIUM', 'HIGH', 'URGENT');

-- Add a column using the custom type
ALTER TABLE customer_feedback
ADD COLUMN urgency order_priority DEFAULT 'MEDIUM';

-- ============================================================================
-- 20. Creating a domain (constrained type)
-- ============================================================================
CREATE DOMAIN email_address AS VARCHAR(255)
    CHECK (VALUE ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');

CREATE DOMAIN positive_decimal AS NUMERIC(10, 2)
    CHECK (VALUE >= 0);

-- Example usage
CREATE TABLE newsletter_subscribers (
    subscriber_id SERIAL PRIMARY KEY,
    email email_address NOT NULL UNIQUE,
    subscribed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- 21. Creating a function/stored procedure
-- ============================================================================
CREATE OR REPLACE FUNCTION get_customer_lifetime_value(p_customer_id INTEGER)
RETURNS NUMERIC(10, 2) AS $$
DECLARE
    v_total NUMERIC(10, 2);
BEGIN
    SELECT COALESCE(SUM(total_amount), 0)
    INTO v_total
    FROM orders
    WHERE customer_id = p_customer_id
        AND order_status NOT IN ('CANCELLED', 'REFUNDED');
    
    RETURN v_total;
END;
$$ LANGUAGE plpgsql;

-- Test the function
SELECT 
    customer_id,
    first_name || ' ' || last_name as name,
    get_customer_lifetime_value(customer_id) as lifetime_value
FROM customers
ORDER BY get_customer_lifetime_value(customer_id) DESC
LIMIT 5;

-- ============================================================================
-- 22. DROP FUNCTION
-- ============================================================================
-- Create a temporary function to demonstrate dropping
CREATE FUNCTION temp_function() RETURNS INTEGER AS $$
BEGIN
    RETURN 1;
END;
$$ LANGUAGE plpgsql;

-- Drop it
DROP FUNCTION temp_function();

-- ============================================================================
-- 23. Creating a trigger
-- ============================================================================
CREATE OR REPLACE FUNCTION log_feedback_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' AND OLD.status != NEW.status THEN
        INSERT INTO audit_log (table_name, record_id, action, old_values, new_values)
        VALUES (
            'customer_feedback',
            NEW.feedback_id,
            'STATUS_CHANGE',
            json_build_object('old_status', OLD.status)::jsonb,
            json_build_object('new_status', NEW.status)::jsonb
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_feedback_status_change
    AFTER UPDATE ON customer_feedback
    FOR EACH ROW
    EXECUTE FUNCTION log_feedback_changes();

-- ============================================================================
-- 24. DROP TRIGGER
-- ============================================================================
-- We'll keep the trigger for this example, but here's how to drop it:
-- DROP TRIGGER tr_feedback_status_change ON customer_feedback;

-- ============================================================================
-- 25. Creating constraints
-- ============================================================================
-- Foreign key constraint
ALTER TABLE customer_feedback
ADD CONSTRAINT fk_customer_feedback_customer
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
    ON DELETE CASCADE;

-- Unique constraint
ALTER TABLE newsletter_subscribers
ADD CONSTRAINT unique_subscriber_email UNIQUE (email);

-- Check constraint
ALTER TABLE customer_feedback
ADD CONSTRAINT check_resolved_date
    CHECK (resolved_at IS NULL OR resolved_at > submitted_at);

-- ============================================================================
-- 26. DROP CONSTRAINT
-- ============================================================================
-- Add a temporary constraint to demonstrate dropping
ALTER TABLE customer_feedback
ADD CONSTRAINT temp_constraint CHECK (priority > 0);

-- Drop it
ALTER TABLE customer_feedback
DROP CONSTRAINT temp_constraint;

-- ============================================================================
-- 27. Creating a schema
-- ============================================================================
CREATE SCHEMA reporting;

-- Create a table in the new schema
CREATE TABLE reporting.monthly_summaries (
    summary_id SERIAL PRIMARY KEY,
    month DATE NOT NULL,
    total_revenue NUMERIC(12, 2),
    total_orders INTEGER,
    unique_customers INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- 28. GRANT permissions
-- ============================================================================
-- Create a role
CREATE ROLE readonly_user;

-- Grant SELECT permission
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly_user;
GRANT SELECT ON ALL TABLES IN SCHEMA reporting TO readonly_user;

-- Grant usage on sequences
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO readonly_user;

-- ============================================================================
-- 29. REVOKE permissions
-- ============================================================================
REVOKE INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public FROM readonly_user;

-- ============================================================================
-- 30. Clean up demonstration objects
-- ============================================================================
-- Drop the temporary objects we created for demonstration
DROP TABLE IF EXISTS renamed_temp_table CASCADE;
DROP SEQUENCE IF EXISTS invoice_number_seq;
DROP MATERIALIZED VIEW IF EXISTS mv_daily_sales_summary;
DROP TABLE IF EXISTS newsletter_subscribers CASCADE;
DROP DOMAIN IF EXISTS email_address CASCADE;
DROP DOMAIN IF EXISTS positive_decimal CASCADE;
DROP TYPE IF EXISTS order_priority CASCADE;
DROP SCHEMA IF EXISTS reporting CASCADE;
DROP ROLE IF EXISTS readonly_user;

-- Keep customer_feedback table as it's useful for the project

-- ============================================================================
-- Summary query: Show all user-created objects
-- ============================================================================
SELECT 
    schemaname,
    tablename as object_name,
    'TABLE' as object_type
FROM pg_tables
WHERE schemaname = 'public'

UNION ALL

SELECT 
    schemaname,
    viewname,
    'VIEW'
FROM pg_views
WHERE schemaname = 'public'

UNION ALL

SELECT 
    schemaname,
    indexname,
    'INDEX'
FROM pg_indexes
WHERE schemaname = 'public'

ORDER BY object_type, object_name;

-- ============================================================================
-- Summary
-- ============================================================================
COMMENT ON TABLE customer_feedback IS 
'This file demonstrates: CREATE/ALTER/DROP TABLE, adding/modifying/dropping columns,
adding/dropping constraints, creating indexes (regular/unique/partial),
creating/dropping views and materialized views, sequences, custom types,
domains, functions, triggers, schemas, and permission management (GRANT/REVOKE)';


