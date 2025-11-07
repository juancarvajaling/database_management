-- ============================================================================
-- Functions and Stored Procedures Creation Script
-- ============================================================================
-- Competency: Creates and modifies database objects
-- Competency: Wraps queries into transactions to ensure data consistency and integrity
-- Description: Creates functions, stored procedures, and triggers
-- ============================================================================

-- ============================================================================
-- FUNCTION: Update timestamp on record modification
-- ============================================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION update_updated_at_column() IS 'Automatically updates the updated_at timestamp when a row is modified';

-- Create triggers for all tables with updated_at column
CREATE TRIGGER tr_customers_updated_at
    BEFORE UPDATE ON customers
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER tr_products_updated_at
    BEFORE UPDATE ON products
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER tr_inventory_updated_at
    BEFORE UPDATE ON inventory
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER tr_orders_updated_at
    BEFORE UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER tr_reviews_updated_at
    BEFORE UPDATE ON reviews
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- FUNCTION: Calculate customer tier based on lifetime value
-- ============================================================================
CREATE OR REPLACE FUNCTION calculate_customer_tier(p_customer_id INTEGER)
RETURNS VARCHAR(20) AS $$
DECLARE
    v_lifetime_value DECIMAL(10, 2);
    v_tier VARCHAR(20);
BEGIN
    -- Calculate total spending
    SELECT COALESCE(SUM(total_amount), 0)
    INTO v_lifetime_value
    FROM orders
    WHERE customer_id = p_customer_id
        AND order_status NOT IN ('CANCELLED', 'REFUNDED');
    
    -- Determine tier based on spending
    IF v_lifetime_value >= 10000 THEN
        v_tier := 'PLATINUM';
    ELSIF v_lifetime_value >= 5000 THEN
        v_tier := 'GOLD';
    ELSIF v_lifetime_value >= 1000 THEN
        v_tier := 'SILVER';
    ELSE
        v_tier := 'BRONZE';
    END IF;
    
    RETURN v_tier;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION calculate_customer_tier(INTEGER) IS 'Calculates customer tier based on lifetime purchase value';

-- ============================================================================
-- FUNCTION: Check product availability
-- ============================================================================
CREATE OR REPLACE FUNCTION check_product_availability(
    p_product_id INTEGER,
    p_quantity INTEGER,
    p_warehouse_location VARCHAR(100) DEFAULT 'MAIN'
)
RETURNS BOOLEAN AS $$
DECLARE
    v_available INTEGER;
BEGIN
    SELECT quantity_available - quantity_reserved
    INTO v_available
    FROM inventory
    WHERE product_id = p_product_id
        AND warehouse_location = p_warehouse_location;
    
    RETURN COALESCE(v_available, 0) >= p_quantity;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION check_product_availability(INTEGER, INTEGER, VARCHAR) IS 'Checks if sufficient inventory is available for an order';

-- ============================================================================
-- FUNCTION: Reserve inventory for order
-- ============================================================================
CREATE OR REPLACE FUNCTION reserve_inventory(
    p_product_id INTEGER,
    p_quantity INTEGER,
    p_warehouse_location VARCHAR(100) DEFAULT 'MAIN'
)
RETURNS BOOLEAN AS $$
DECLARE
    v_available INTEGER;
BEGIN
    -- Check availability
    SELECT quantity_available - quantity_reserved
    INTO v_available
    FROM inventory
    WHERE product_id = p_product_id
        AND warehouse_location = p_warehouse_location
    FOR UPDATE;
    
    IF COALESCE(v_available, 0) < p_quantity THEN
        RETURN FALSE;
    END IF;
    
    -- Reserve the inventory
    UPDATE inventory
    SET quantity_reserved = quantity_reserved + p_quantity
    WHERE product_id = p_product_id
        AND warehouse_location = p_warehouse_location;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION reserve_inventory(INTEGER, INTEGER, VARCHAR) IS 'Reserves inventory for an order (use within a transaction)';

-- ============================================================================
-- FUNCTION: Release inventory reservation
-- ============================================================================
CREATE OR REPLACE FUNCTION release_inventory(
    p_product_id INTEGER,
    p_quantity INTEGER,
    p_warehouse_location VARCHAR(100) DEFAULT 'MAIN'
)
RETURNS VOID AS $$
BEGIN
    UPDATE inventory
    SET quantity_reserved = GREATEST(0, quantity_reserved - p_quantity)
    WHERE product_id = p_product_id
        AND warehouse_location = p_warehouse_location;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION release_inventory(INTEGER, INTEGER, VARCHAR) IS 'Releases reserved inventory (for cancelled orders)';

-- ============================================================================
-- FUNCTION: Complete inventory transaction (order shipped)
-- ============================================================================
CREATE OR REPLACE FUNCTION complete_inventory_transaction(
    p_product_id INTEGER,
    p_quantity INTEGER,
    p_warehouse_location VARCHAR(100) DEFAULT 'MAIN'
)
RETURNS VOID AS $$
BEGIN
    UPDATE inventory
    SET quantity_available = quantity_available - p_quantity,
        quantity_reserved = quantity_reserved - p_quantity
    WHERE product_id = p_product_id
        AND warehouse_location = p_warehouse_location;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION complete_inventory_transaction(INTEGER, INTEGER, VARCHAR) IS 'Completes inventory transaction when order ships';

-- ============================================================================
-- FUNCTION: Calculate order total
-- ============================================================================
CREATE OR REPLACE FUNCTION calculate_order_total(p_order_id INTEGER)
RETURNS DECIMAL(10, 2) AS $$
DECLARE
    v_subtotal DECIMAL(10, 2);
    v_tax_rate DECIMAL(5, 4) := 0.0875; -- 8.75% tax rate
    v_tax_amount DECIMAL(10, 2);
    v_shipping DECIMAL(10, 2);
    v_discount DECIMAL(10, 2);
    v_total DECIMAL(10, 2);
BEGIN
    -- Calculate subtotal from order items
    SELECT COALESCE(SUM(line_total), 0)
    INTO v_subtotal
    FROM order_items
    WHERE order_id = p_order_id;
    
    -- Get shipping cost and discount from order
    SELECT shipping_cost, discount_amount
    INTO v_shipping, v_discount
    FROM orders
    WHERE order_id = p_order_id;
    
    -- Calculate tax
    v_tax_amount := ROUND(v_subtotal * v_tax_rate, 2);
    
    -- Calculate total
    v_total := v_subtotal + v_tax_amount + COALESCE(v_shipping, 0) - COALESCE(v_discount, 0);
    
    RETURN v_total;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION calculate_order_total(INTEGER) IS 'Calculates the total amount for an order including tax and fees';

-- ============================================================================
-- FUNCTION: Get product rating summary
-- ============================================================================
CREATE OR REPLACE FUNCTION get_product_rating_summary(p_product_id INTEGER)
RETURNS TABLE (
    average_rating DECIMAL(3, 2),
    total_reviews INTEGER,
    five_star INTEGER,
    four_star INTEGER,
    three_star INTEGER,
    two_star INTEGER,
    one_star INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        ROUND(AVG(rating), 2)::DECIMAL(3, 2),
        COUNT(*)::INTEGER,
        COUNT(CASE WHEN rating = 5 THEN 1 END)::INTEGER,
        COUNT(CASE WHEN rating = 4 THEN 1 END)::INTEGER,
        COUNT(CASE WHEN rating = 3 THEN 1 END)::INTEGER,
        COUNT(CASE WHEN rating = 2 THEN 1 END)::INTEGER,
        COUNT(CASE WHEN rating = 1 THEN 1 END)::INTEGER
    FROM reviews
    WHERE product_id = p_product_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_product_rating_summary(INTEGER) IS 'Returns detailed rating breakdown for a product';

-- ============================================================================
-- FUNCTION: Apply promotion to order
-- ============================================================================
CREATE OR REPLACE FUNCTION apply_promotion(
    p_order_id INTEGER,
    p_promotion_code VARCHAR(50)
)
RETURNS DECIMAL(10, 2) AS $$
DECLARE
    v_promotion_id INTEGER;
    v_discount_type VARCHAR(20);
    v_discount_value DECIMAL(10, 2);
    v_min_purchase DECIMAL(10, 2);
    v_max_discount DECIMAL(10, 2);
    v_subtotal DECIMAL(10, 2);
    v_discount_applied DECIMAL(10, 2);
BEGIN
    -- Get promotion details
    SELECT promotion_id, discount_type, discount_value, min_purchase_amount, max_discount_amount
    INTO v_promotion_id, v_discount_type, v_discount_value, v_min_purchase, v_max_discount
    FROM promotions
    WHERE promotion_code = p_promotion_code
        AND is_active = TRUE
        AND CURRENT_TIMESTAMP BETWEEN start_date AND end_date
        AND (usage_limit IS NULL OR usage_count < usage_limit);
    
    IF v_promotion_id IS NULL THEN
        RAISE EXCEPTION 'Invalid or expired promotion code';
    END IF;
    
    -- Get order subtotal
    SELECT subtotal INTO v_subtotal
    FROM orders
    WHERE order_id = p_order_id;
    
    -- Check minimum purchase requirement
    IF v_subtotal < v_min_purchase THEN
        RAISE EXCEPTION 'Order does not meet minimum purchase amount';
    END IF;
    
    -- Calculate discount
    IF v_discount_type = 'PERCENTAGE' THEN
        v_discount_applied := ROUND(v_subtotal * (v_discount_value / 100), 2);
    ELSE
        v_discount_applied := v_discount_value;
    END IF;
    
    -- Apply maximum discount cap if exists
    IF v_max_discount IS NOT NULL AND v_discount_applied > v_max_discount THEN
        v_discount_applied := v_max_discount;
    END IF;
    
    -- Record promotion usage
    INSERT INTO order_promotions (order_id, promotion_id, discount_applied)
    VALUES (p_order_id, v_promotion_id, v_discount_applied);
    
    -- Update promotion usage count
    UPDATE promotions
    SET usage_count = usage_count + 1
    WHERE promotion_id = v_promotion_id;
    
    RETURN v_discount_applied;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION apply_promotion(INTEGER, VARCHAR) IS 'Applies a promotion code to an order and returns discount amount';

-- ============================================================================
-- TRIGGER: Audit log for order changes
-- ============================================================================
CREATE OR REPLACE FUNCTION audit_order_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO audit_log (table_name, record_id, action, new_values, changed_by)
        VALUES ('orders', NEW.order_id, 'INSERT', row_to_json(NEW)::jsonb, current_user);
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO audit_log (table_name, record_id, action, old_values, new_values, changed_by)
        VALUES ('orders', NEW.order_id, 'UPDATE', row_to_json(OLD)::jsonb, row_to_json(NEW)::jsonb, current_user);
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO audit_log (table_name, record_id, action, old_values, changed_by)
        VALUES ('orders', OLD.order_id, 'DELETE', row_to_json(OLD)::jsonb, current_user);
        RETURN OLD;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_audit_orders
    AFTER INSERT OR UPDATE OR DELETE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION audit_order_changes();

COMMENT ON FUNCTION audit_order_changes() IS 'Automatically logs all changes to orders table';

-- ============================================================================
-- TRIGGER: Validate inventory before order item insert
-- ============================================================================
CREATE OR REPLACE FUNCTION validate_order_item_inventory()
RETURNS TRIGGER AS $$
DECLARE
    v_available BOOLEAN;
BEGIN
    v_available := check_product_availability(NEW.product_id, NEW.quantity);
    
    IF NOT v_available THEN
        RAISE EXCEPTION 'Insufficient inventory for product ID %', NEW.product_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_validate_inventory
    BEFORE INSERT ON order_items
    FOR EACH ROW
    EXECUTE FUNCTION validate_order_item_inventory();

COMMENT ON FUNCTION validate_order_item_inventory() IS 'Validates inventory availability before adding items to order';

-- ============================================================================
-- Display all functions and triggers
-- ============================================================================
SELECT 
    n.nspname as schema,
    p.proname as function_name,
    pg_get_function_arguments(p.oid) as arguments,
    pg_get_functiondef(p.oid) as definition
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
    AND p.prokind IN ('f', 'p')
ORDER BY p.proname;


