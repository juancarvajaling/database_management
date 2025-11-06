-- ============================================================================
-- Data Selection Queries
-- ============================================================================
-- Competency: Selects data from a database using query language
-- Description: Demonstrates various SELECT statement techniques
-- ============================================================================

-- ============================================================================
-- 1. BASIC SELECT - All columns
-- ============================================================================
-- Retrieve all customers
SELECT * FROM customers;

-- ============================================================================
-- 2. SELECT with specific columns
-- ============================================================================
-- Get customer contact information
SELECT 
    customer_id,
    first_name,
    last_name,
    email,
    phone
FROM customers;

-- ============================================================================
-- 3. SELECT with WHERE clause - Single condition
-- ============================================================================
-- Find all GOLD tier customers
SELECT 
    customer_id,
    first_name,
    last_name,
    email,
    customer_tier
FROM customers
WHERE customer_tier = 'GOLD';

-- ============================================================================
-- 4. SELECT with multiple conditions (AND)
-- ============================================================================
-- Find active PLATINUM customers
SELECT 
    customer_id,
    first_name,
    last_name,
    email,
    customer_tier,
    is_active
FROM customers
WHERE customer_tier = 'PLATINUM' 
    AND is_active = TRUE;

-- ============================================================================
-- 5. SELECT with OR conditions
-- ============================================================================
-- Find customers who are either GOLD or PLATINUM tier
SELECT 
    customer_id,
    first_name || ' ' || last_name as full_name,
    email,
    customer_tier
FROM customers
WHERE customer_tier = 'GOLD' 
    OR customer_tier = 'PLATINUM';

-- ============================================================================
-- 6. SELECT with IN operator
-- ============================================================================
-- More elegant way to select multiple tier levels
SELECT 
    customer_id,
    first_name,
    last_name,
    customer_tier
FROM customers
WHERE customer_tier IN ('GOLD', 'PLATINUM');

-- ============================================================================
-- 7. SELECT with NOT IN
-- ============================================================================
-- Find products not in Electronics or Books categories
SELECT 
    product_id,
    product_name,
    category_id
FROM products
WHERE category_id NOT IN (1, 4);

-- ============================================================================
-- 8. SELECT with BETWEEN
-- ============================================================================
-- Find products priced between $50 and $500
SELECT 
    product_id,
    product_name,
    unit_price
FROM products
WHERE unit_price BETWEEN 50.00 AND 500.00;

-- ============================================================================
-- 9. SELECT with LIKE pattern matching
-- ============================================================================
-- Find all products with "Pro" in the name
SELECT 
    product_id,
    product_name,
    unit_price
FROM products
WHERE product_name LIKE '%Pro%';

-- ============================================================================
-- 10. SELECT with ILIKE (case-insensitive)
-- ============================================================================
-- Find customers with email from gmail
SELECT 
    customer_id,
    first_name,
    last_name,
    email
FROM customers
WHERE email ILIKE '%@gmail.com';

-- ============================================================================
-- 11. SELECT with NULL checks
-- ============================================================================
-- Find products without a description
SELECT 
    product_id,
    product_name,
    description
FROM products
WHERE description IS NULL;

-- Find products with a description
SELECT 
    product_id,
    product_name,
    description
FROM products
WHERE description IS NOT NULL;

-- ============================================================================
-- 12. SELECT with date filtering
-- ============================================================================
-- Find orders placed in 2024
SELECT 
    order_id,
    customer_id,
    order_date,
    total_amount
FROM orders
WHERE EXTRACT(YEAR FROM order_date) = 2024;

-- ============================================================================
-- 13. SELECT with date range
-- ============================================================================
-- Find orders from January 2024
SELECT 
    order_id,
    customer_id,
    order_date,
    total_amount,
    order_status
FROM orders
WHERE order_date BETWEEN '2024-01-01' AND '2024-01-31 23:59:59';

-- ============================================================================
-- 14. SELECT with comparison operators
-- ============================================================================
-- Find high-value orders (over $1000)
SELECT 
    order_id,
    customer_id,
    order_date,
    total_amount
FROM orders
WHERE total_amount > 1000.00
ORDER BY total_amount DESC;

-- ============================================================================
-- 15. SELECT with DISTINCT
-- ============================================================================
-- Get unique customer tiers
SELECT DISTINCT customer_tier
FROM customers
ORDER BY customer_tier;

-- ============================================================================
-- 16. SELECT with column aliases
-- ============================================================================
-- Format customer names with aliases
SELECT 
    customer_id as id,
    first_name || ' ' || last_name as full_name,
    email as contact_email,
    customer_tier as loyalty_level
FROM customers;

-- ============================================================================
-- 17. SELECT with calculated fields
-- ============================================================================
-- Calculate profit margin for each product
SELECT 
    product_id,
    product_name,
    unit_price,
    cost_price,
    unit_price - cost_price as profit_per_unit,
    ROUND(((unit_price - cost_price) / cost_price * 100), 2) as profit_margin_percent
FROM products
WHERE is_active = TRUE;

-- ============================================================================
-- 18. SELECT with CASE expressions
-- ============================================================================
-- Categorize products by price range
SELECT 
    product_id,
    product_name,
    unit_price,
    CASE 
        WHEN unit_price < 50 THEN 'Budget'
        WHEN unit_price BETWEEN 50 AND 500 THEN 'Mid-Range'
        WHEN unit_price BETWEEN 500 AND 1500 THEN 'Premium'
        ELSE 'Luxury'
    END as price_category
FROM products
ORDER BY unit_price;

-- ============================================================================
-- 19. SELECT with date functions
-- ============================================================================
-- Show customer age and account age
SELECT 
    customer_id,
    first_name,
    last_name,
    date_of_birth,
    EXTRACT(YEAR FROM AGE(date_of_birth)) as age,
    created_at,
    EXTRACT(DAY FROM CURRENT_TIMESTAMP - created_at) as days_as_member
FROM customers;

-- ============================================================================
-- 20. SELECT with string functions
-- ============================================================================
-- Format and manipulate customer data
SELECT 
    customer_id,
    UPPER(last_name) as last_name_upper,
    LOWER(email) as email_lower,
    CONCAT(first_name, ' ', last_name) as full_name,
    LENGTH(email) as email_length,
    SUBSTRING(email FROM POSITION('@' IN email) + 1) as email_domain
FROM customers;

-- ============================================================================
-- 21. SELECT with LIMIT
-- ============================================================================
-- Get top 5 most expensive products
SELECT 
    product_id,
    product_name,
    unit_price
FROM products
ORDER BY unit_price DESC
LIMIT 5;

-- ============================================================================
-- 22. SELECT with OFFSET (pagination)
-- ============================================================================
-- Get products 6-10 (second page of 5 items)
SELECT 
    product_id,
    product_name,
    unit_price
FROM products
ORDER BY product_id
LIMIT 5 OFFSET 5;

-- ============================================================================
-- 23. SELECT with complex WHERE conditions
-- ============================================================================
-- Find orders that are completed, high-value, and from premium customers
SELECT 
    o.order_id,
    o.customer_id,
    c.customer_tier,
    o.order_date,
    o.total_amount,
    o.order_status
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'DELIVERED'
    AND o.payment_status = 'COMPLETED'
    AND o.total_amount > 500
    AND c.customer_tier IN ('GOLD', 'PLATINUM')
ORDER BY o.total_amount DESC;

-- ============================================================================
-- Summary
-- ============================================================================
COMMENT ON COLUMN customers.customer_tier IS 
'These queries demonstrate: basic SELECT, WHERE clauses, multiple conditions, 
pattern matching, date filtering, calculated fields, CASE expressions, 
string/date functions, DISTINCT, LIMIT/OFFSET, and complex conditions';


