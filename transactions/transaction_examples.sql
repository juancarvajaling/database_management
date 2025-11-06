-- ============================================================================
-- Transaction Management Examples
-- ============================================================================
-- Competency: Wraps queries into transactions to ensure data consistency and integrity
-- Description: Demonstrates ACID properties, transaction control, and isolation levels
-- ============================================================================

-- ============================================================================
-- ACID PROPERTIES DEMONSTRATION
-- ============================================================================

-- ============================================================================
-- 1. Basic Transaction - COMMIT
-- ============================================================================
-- Atomicity: All operations succeed or all fail
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

-- ============================================================================
-- 2. Transaction with ROLLBACK
-- ============================================================================
-- Demonstrate rolling back changes
BEGIN;

-- Attempt to create an order with invalid data
INSERT INTO customers (email, first_name, last_name, customer_tier)
VALUES ('test@test.com', 'Test', 'User', 'BRONZE');

-- Get customer ID
SELECT currval('customers_customer_id_seq') as test_customer_id;

-- Oops, we don't want this test data
ROLLBACK;

-- Verify the insert was rolled back
SELECT * FROM customers WHERE email = 'test@test.com';
-- Should return no rows

-- ============================================================================
-- 3. SAVEPOINT - Partial rollback
-- ============================================================================
BEGIN;

-- Insert a customer
INSERT INTO customers (email, first_name, last_name, customer_tier)
VALUES ('savepoint.test@email.com', 'Savepoint', 'Test', 'BRONZE');

SAVEPOINT after_customer_insert;

-- Insert an address
INSERT INTO addresses (customer_id, address_type, street_address, city, state, postal_code, is_default)
VALUES (currval('customers_customer_id_seq'), 'SHIPPING', '123 Test St', 'Test City', 'TS', '12345', TRUE);

SAVEPOINT after_address_insert;

-- Try to insert invalid billing address (missing required fields)
-- This would fail, so we can rollback to savepoint
INSERT INTO addresses (customer_id, address_type, street_address, city, state, postal_code, is_default)
VALUES (currval('customers_customer_id_seq'), 'BILLING', '', '', '', '', TRUE);

-- Rollback to after the shipping address was added
ROLLBACK TO SAVEPOINT after_address_insert;

-- Add a valid billing address
INSERT INTO addresses (customer_id, address_type, street_address, city, state, postal_code, is_default)
VALUES (currval('customers_customer_id_seq'), 'BILLING', '123 Test St', 'Test City', 'TS', '12345', TRUE);

-- Commit all valid changes
COMMIT;

-- Clean up test data
DELETE FROM customers WHERE email = 'savepoint.test@email.com';

-- ============================================================================
-- 4. Transaction ensuring data consistency - Order processing
-- ============================================================================
-- Demonstrates ensuring referential integrity and business logic
BEGIN;

-- Step 1: Verify customer exists and is active
DO $$
DECLARE
    v_customer_id INTEGER := 1;
    v_is_active BOOLEAN;
BEGIN
    SELECT is_active INTO v_is_active
    FROM customers
    WHERE customer_id = v_customer_id;
    
    IF NOT v_is_active THEN
        RAISE EXCEPTION 'Customer is not active';
    END IF;
END $$;

-- Step 2: Check product availability
DO $$
DECLARE
    v_product_id INTEGER := 3;
    v_quantity INTEGER := 1;
    v_available INTEGER;
BEGIN
    SELECT quantity_available - quantity_reserved
    INTO v_available
    FROM inventory
    WHERE product_id = v_product_id AND warehouse_location = 'MAIN';
    
    IF v_available < v_quantity THEN
        RAISE EXCEPTION 'Insufficient inventory';
    END IF;
END $$;

-- Step 3: Reserve inventory
UPDATE inventory
SET quantity_reserved = quantity_reserved + 1
WHERE product_id = 3 AND warehouse_location = 'MAIN';

-- Step 4: Create order with all validated data
-- (Would continue with order creation)

COMMIT;

-- Restore inventory
UPDATE inventory
SET quantity_reserved = quantity_reserved - 1
WHERE product_id = 3 AND warehouse_location = 'MAIN';

-- ============================================================================
-- 5. Concurrent transaction handling - Optimistic locking
-- ============================================================================
-- Demonstrates handling concurrent updates

-- Session 1 simulation:
BEGIN;

SELECT product_name, unit_price, updated_at 
FROM products 
WHERE product_id = 5;

-- User reviews and decides to update price
UPDATE products
SET unit_price = 449.00
WHERE product_id = 5 
    AND updated_at = (SELECT updated_at FROM products WHERE product_id = 5);

COMMIT;

-- ============================================================================
-- 6. Pessimistic locking with SELECT FOR UPDATE
-- ============================================================================
-- Prevents other transactions from modifying the row
BEGIN;

-- Lock the product row for update
SELECT product_id, product_name, unit_price
FROM products
WHERE product_id = 1
FOR UPDATE;

-- Other transactions will wait here until this transaction completes

-- Perform update
UPDATE products
SET unit_price = unit_price * 1.05
WHERE product_id = 1;

COMMIT;

-- ============================================================================
-- 7. Transaction isolation level - READ COMMITTED (default)
-- ============================================================================
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;

-- This transaction will see committed changes from other transactions
SELECT COUNT(*) FROM orders;

-- If another transaction commits an INSERT, this will see the new row
SELECT COUNT(*) FROM orders;

COMMIT;

-- ============================================================================
-- 8. Transaction isolation level - REPEATABLE READ
-- ============================================================================
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;

-- Take a snapshot of data
SELECT COUNT(*) as order_count FROM orders;

-- Even if other transactions commit changes, this transaction will see
-- the same data throughout (phantom reads prevented)
SELECT COUNT(*) as order_count_again FROM orders;

COMMIT;

-- ============================================================================
-- 9. Transaction isolation level - SERIALIZABLE
-- ============================================================================
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;

-- Strictest isolation level
-- Transactions execute as if they were run serially
SELECT SUM(total_amount) FROM orders WHERE order_status = 'DELIVERED';

-- No other transaction can modify this data until commit
UPDATE orders
SET order_status = 'DELIVERED'
WHERE order_status = 'SHIPPED' AND shipped_at < NOW() - INTERVAL '7 days';

COMMIT;

-- ============================================================================
-- 10. Complex transaction - Order fulfillment
-- ============================================================================
-- Demonstrates multi-step business process with consistency checks
BEGIN;

-- Variables for the transaction
DO $$
DECLARE
    v_order_id INTEGER := 10;
    v_order_status VARCHAR(20);
    v_payment_status VARCHAR(20);
BEGIN
    -- Step 1: Verify order is ready to ship
    SELECT order_status, payment_status
    INTO v_order_status, v_payment_status
    FROM orders
    WHERE order_id = v_order_id
    FOR UPDATE;
    
    IF v_order_status != 'PROCESSING' THEN
        RAISE EXCEPTION 'Order is not in PROCESSING status';
    END IF;
    
    IF v_payment_status != 'COMPLETED' THEN
        RAISE EXCEPTION 'Payment has not been completed';
    END IF;
    
    -- Step 2: Reduce inventory for each item
    UPDATE inventory i
    SET 
        quantity_available = i.quantity_available - oi.quantity,
        quantity_reserved = i.quantity_reserved - oi.quantity
    FROM order_items oi
    WHERE i.product_id = oi.product_id
        AND oi.order_id = v_order_id
        AND i.warehouse_location = 'MAIN';
    
    -- Step 3: Update order status
    UPDATE orders
    SET 
        order_status = 'SHIPPED',
        shipped_at = CURRENT_TIMESTAMP
    WHERE order_id = v_order_id;
    
    -- Step 4: Log the shipment in audit trail
    INSERT INTO audit_log (table_name, record_id, action, new_values)
    VALUES (
        'orders',
        v_order_id,
        'SHIPPED',
        json_build_object(
            'shipped_at', CURRENT_TIMESTAMP,
            'order_id', v_order_id
        )::jsonb
    );
    
    RAISE NOTICE 'Order % successfully shipped', v_order_id;
END $$;

ROLLBACK; -- Don't actually commit this demo transaction

-- ============================================================================
-- 11. Transaction with error handling
-- ============================================================================
DO $$
BEGIN
    BEGIN
        -- Start a sub-transaction
        INSERT INTO customers (email, first_name, last_name)
        VALUES ('error.test@email.com', 'Error', 'Test');
        
        -- This will fail due to missing required tier
        INSERT INTO orders (customer_id, shipping_address_id, billing_address_id, subtotal, total_amount)
        VALUES (9999, 1, 1, 100.00, 100.00);
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Error caught: %', SQLERRM;
            -- Handle the error gracefully
            RAISE NOTICE 'Transaction rolled back due to error';
    END;
END $$;

-- ============================================================================
-- 12. Batch processing with transaction
-- ============================================================================
-- Process multiple updates in a single transaction
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

ROLLBACK; -- Demo only, don't commit

-- ============================================================================
-- 13. Transaction with deferred constraints
-- ============================================================================
-- Create a table with deferrable constraint for demonstration
CREATE TEMP TABLE temp_employees (
    employee_id INTEGER PRIMARY KEY,
    manager_id INTEGER,
    name VARCHAR(100)
);

ALTER TABLE temp_employees
ADD CONSTRAINT fk_manager FOREIGN KEY (manager_id) 
REFERENCES temp_employees(employee_id)
DEFERRABLE INITIALLY DEFERRED;

BEGIN;

-- These inserts would normally violate FK constraint
-- But with DEFERRED, they're checked at commit time
INSERT INTO temp_employees VALUES (2, 1, 'Employee');
INSERT INTO temp_employees VALUES (1, NULL, 'Manager');

COMMIT;

-- ============================================================================
-- 14. Compensating transaction (for demonstration)
-- ============================================================================
-- Demonstrates how to undo a committed transaction with a compensating transaction
BEGIN;

-- Original transaction: Refund an order
UPDATE orders
SET 
    order_status = 'REFUNDED',
    payment_status = 'REFUNDED'
WHERE order_id = 5;

-- Restore inventory
UPDATE inventory i
SET 
    quantity_available = i.quantity_available + oi.quantity
FROM order_items oi
WHERE i.product_id = oi.product_id
    AND oi.order_id = 5
    AND i.warehouse_location = 'MAIN';

-- Log the refund
INSERT INTO audit_log (table_name, record_id, action, new_values)
VALUES ('orders', 5, 'REFUND', json_build_object('refunded_at', CURRENT_TIMESTAMP)::jsonb);

ROLLBACK; -- Demo only

-- ============================================================================
-- 15. Two-phase commit pattern (simplified)
-- ============================================================================
-- Demonstrates coordinating multiple operations
BEGIN;

-- Phase 1: Prepare all operations
SAVEPOINT phase1_complete;

-- Operation 1: Update order
UPDATE orders
SET order_status = 'CONFIRMED'
WHERE order_id = 6 AND order_status = 'PENDING';

-- Operation 2: Send confirmation (simulated)
INSERT INTO audit_log (table_name, record_id, action, new_values)
VALUES ('orders', 6, 'CONFIRMED', json_build_object('confirmed_at', CURRENT_TIMESTAMP)::jsonb);

-- Check if all operations succeeded
DO $$
DECLARE
    v_operations_success BOOLEAN := TRUE;
BEGIN
    -- Verify operation results
    IF NOT EXISTS (SELECT 1 FROM orders WHERE order_id = 6 AND order_status = 'CONFIRMED') THEN
        v_operations_success := FALSE;
    END IF;
    
    IF NOT v_operations_success THEN
        RAISE EXCEPTION 'One or more operations failed';
    END IF;
END $$;

-- Phase 2: Commit if all operations succeeded
COMMIT;

-- ============================================================================
-- Transaction Best Practices Summary
-- ============================================================================
/*
1. Keep transactions SHORT - lock resources for minimal time
2. Use appropriate isolation levels - balance consistency vs. performance
3. Handle errors gracefully - use EXCEPTION blocks
4. Use SAVEPOINT for complex operations needing partial rollback
5. Lock only what you need - use SELECT FOR UPDATE judiciously
6. Avoid user interaction within transactions
7. Order operations to minimize deadlock risk
8. Use explicit BEGIN/COMMIT for clarity
9. Consider optimistic locking for high-concurrency scenarios
10. Log important state changes in audit tables
*/

-- ============================================================================
-- Summary
-- ============================================================================
COMMENT ON TABLE orders IS 
'This file demonstrates: Basic transactions (BEGIN/COMMIT/ROLLBACK),
SAVEPOINT for partial rollback, data consistency checks, optimistic and
pessimistic locking, transaction isolation levels (READ COMMITTED,
REPEATABLE READ, SERIALIZABLE), complex multi-step transactions,
error handling, batch processing, deferred constraints, compensating
transactions, and two-phase commit patterns';


