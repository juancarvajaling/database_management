-- ============================================================================
-- Sample Data Insertion Script
-- ============================================================================
-- Competency: Selects data from a database using query language
-- Description: Populates database with realistic sample data for testing
-- ============================================================================

SET search_path TO public;

-- ============================================================================
-- INSERT PRODUCT CATEGORIES
-- ============================================================================
INSERT INTO product_categories (category_name, parent_category_id, description) VALUES
('Electronics', NULL, 'Electronic devices and accessories'),
('Clothing', NULL, 'Apparel and fashion items'),
('Home & Garden', NULL, 'Home improvement and garden supplies'),
('Books', NULL, 'Physical and digital books'),
('Sports & Outdoors', NULL, 'Sports equipment and outdoor gear');

-- Sub-categories
INSERT INTO product_categories (category_name, parent_category_id, description) VALUES
('Laptops', 1, 'Laptop computers'),
('Smartphones', 1, 'Mobile phones and accessories'),
('Headphones', 1, 'Audio equipment'),
('Men''s Clothing', 2, 'Men''s apparel'),
('Women''s Clothing', 2, 'Women''s apparel'),
('Furniture', 3, 'Home furniture'),
('Kitchen', 3, 'Kitchen appliances and tools'),
('Fiction', 4, 'Fiction books'),
('Non-Fiction', 4, 'Non-fiction books'),
('Fitness', 5, 'Fitness equipment');

-- ============================================================================
-- INSERT PRODUCTS
-- ============================================================================
INSERT INTO products (product_name, category_id, sku, description, unit_price, cost_price, weight_kg) VALUES
-- Electronics
('MacBook Pro 16"', 6, 'LAPTOP-MBP16-001', 'Apple MacBook Pro 16-inch with M2 chip', 2499.00, 1800.00, 2.1),
('Dell XPS 15', 6, 'LAPTOP-DELLXPS-001', 'Dell XPS 15 with Intel i7 processor', 1899.00, 1400.00, 1.9),
('iPhone 15 Pro', 7, 'PHONE-IP15PRO-001', 'Apple iPhone 15 Pro 256GB', 1099.00, 850.00, 0.2),
('Samsung Galaxy S24', 7, 'PHONE-SAMS24-001', 'Samsung Galaxy S24 Ultra', 1199.00, 900.00, 0.23),
('Sony WH-1000XM5', 8, 'AUDIO-SONY-001', 'Sony noise-cancelling headphones', 399.00, 250.00, 0.25),
('AirPods Pro', 8, 'AUDIO-APP-001', 'Apple AirPods Pro with MagSafe', 249.00, 180.00, 0.05),

-- Clothing
('Men''s Cotton T-Shirt', 9, 'CLOTH-MTSHIRT-001', 'Comfortable cotton t-shirt for men', 29.99, 12.00, 0.2),
('Men''s Denim Jeans', 9, 'CLOTH-MJEANS-001', 'Classic fit denim jeans', 79.99, 35.00, 0.6),
('Women''s Summer Dress', 10, 'CLOTH-WDRESS-001', 'Floral print summer dress', 89.99, 40.00, 0.3),
('Women''s Yoga Pants', 10, 'CLOTH-WYOGA-001', 'High-waist yoga pants', 59.99, 25.00, 0.25),

-- Home & Garden
('Leather Sofa', 11, 'FURN-SOFA-001', '3-seater leather sofa', 1299.00, 700.00, 85.0),
('Dining Table Set', 11, 'FURN-DINE-001', 'Wooden dining table with 6 chairs', 899.00, 500.00, 95.0),
('Coffee Maker', 12, 'KITCHEN-COFFEE-001', 'Programmable coffee maker', 89.99, 45.00, 2.5),
('Blender Pro', 12, 'KITCHEN-BLEND-001', 'High-power blender', 149.99, 75.00, 3.2),

-- Books
('The Great Gatsby', 13, 'BOOK-GATSBY-001', 'Classic American novel', 14.99, 7.00, 0.3),
('1984', 13, 'BOOK-1984-001', 'Dystopian novel by George Orwell', 15.99, 7.50, 0.32),
('Sapiens', 14, 'BOOK-SAPIENS-001', 'A brief history of humankind', 24.99, 12.00, 0.6),
('Atomic Habits', 14, 'BOOK-HABITS-001', 'Self-improvement book', 19.99, 9.50, 0.45),

-- Sports & Outdoors
('Yoga Mat Premium', 15, 'FITNESS-YMAT-001', 'Extra thick yoga mat', 49.99, 20.00, 1.2),
('Dumbbell Set', 15, 'FITNESS-DUMB-001', 'Adjustable dumbbell set 5-50 lbs', 299.99, 150.00, 25.0);

-- ============================================================================
-- INSERT CUSTOMERS
-- ============================================================================
INSERT INTO customers (email, first_name, last_name, phone, date_of_birth, customer_tier) VALUES
('john.doe@email.com', 'John', 'Doe', '555-0101', '1985-03-15', 'GOLD'),
('jane.smith@email.com', 'Jane', 'Smith', '555-0102', '1990-07-22', 'PLATINUM'),
('mike.johnson@email.com', 'Mike', 'Johnson', '555-0103', '1988-11-30', 'SILVER'),
('sarah.williams@email.com', 'Sarah', 'Williams', '555-0104', '1992-05-18', 'BRONZE'),
('david.brown@email.com', 'David', 'Brown', '555-0105', '1987-09-25', 'GOLD'),
('emily.davis@email.com', 'Emily', 'Davis', '555-0106', '1995-02-14', 'SILVER'),
('robert.miller@email.com', 'Robert', 'Miller', '555-0107', '1983-12-08', 'PLATINUM'),
('lisa.wilson@email.com', 'Lisa', 'Wilson', '555-0108', '1991-06-03', 'BRONZE'),
('james.moore@email.com', 'James', 'Moore', '555-0109', '1986-08-19', 'SILVER'),
('amanda.taylor@email.com', 'Amanda', 'Taylor', '555-0110', '1993-04-27', 'GOLD');

-- ============================================================================
-- INSERT ADDRESSES
-- ============================================================================
INSERT INTO addresses (customer_id, address_type, street_address, city, state, postal_code, country, is_default) VALUES
(1, 'SHIPPING', '123 Main St', 'New York', 'NY', '10001', 'USA', TRUE),
(1, 'BILLING', '123 Main St', 'New York', 'NY', '10001', 'USA', TRUE),
(2, 'SHIPPING', '456 Oak Ave', 'Los Angeles', 'CA', '90001', 'USA', TRUE),
(2, 'BILLING', '456 Oak Ave', 'Los Angeles', 'CA', '90001', 'USA', TRUE),
(3, 'SHIPPING', '789 Pine Rd', 'Chicago', 'IL', '60601', 'USA', TRUE),
(3, 'BILLING', '789 Pine Rd', 'Chicago', 'IL', '60601', 'USA', TRUE),
(4, 'SHIPPING', '321 Elm St', 'Houston', 'TX', '77001', 'USA', TRUE),
(4, 'BILLING', '321 Elm St', 'Houston', 'TX', '77001', 'USA', TRUE),
(5, 'SHIPPING', '654 Maple Dr', 'Phoenix', 'AZ', '85001', 'USA', TRUE),
(5, 'BILLING', '654 Maple Dr', 'Phoenix', 'AZ', '85001', 'USA', TRUE),
(6, 'SHIPPING', '987 Cedar Ln', 'Philadelphia', 'PA', '19101', 'USA', TRUE),
(6, 'BILLING', '987 Cedar Ln', 'Philadelphia', 'PA', '19101', 'USA', TRUE),
(7, 'SHIPPING', '147 Birch Way', 'San Antonio', 'TX', '78201', 'USA', TRUE),
(7, 'BILLING', '147 Birch Way', 'San Antonio', 'TX', '78201', 'USA', TRUE),
(8, 'SHIPPING', '258 Spruce Ave', 'San Diego', 'CA', '92101', 'USA', TRUE),
(8, 'BILLING', '258 Spruce Ave', 'San Diego', 'CA', '92101', 'USA', TRUE),
(9, 'SHIPPING', '369 Walnut St', 'Dallas', 'TX', '75201', 'USA', TRUE),
(9, 'BILLING', '369 Walnut St', 'Dallas', 'TX', '75201', 'USA', TRUE),
(10, 'SHIPPING', '741 Cherry Blvd', 'San Jose', 'CA', '95101', 'USA', TRUE),
(10, 'BILLING', '741 Cherry Blvd', 'San Jose', 'CA', '95101', 'USA', TRUE);

-- ============================================================================
-- INSERT INVENTORY
-- ============================================================================
INSERT INTO inventory (product_id, warehouse_location, quantity_available, quantity_reserved, reorder_level, reorder_quantity) VALUES
-- Electronics
(1, 'MAIN', 15, 2, 5, 10),
(2, 'MAIN', 20, 3, 5, 15),
(3, 'MAIN', 50, 8, 20, 30),
(4, 'MAIN', 45, 5, 20, 30),
(5, 'MAIN', 30, 4, 10, 20),
(6, 'MAIN', 40, 6, 15, 25),
-- Clothing
(7, 'MAIN', 200, 15, 50, 100),
(8, 'MAIN', 150, 12, 40, 80),
(9, 'MAIN', 180, 18, 45, 90),
(10, 'MAIN', 160, 14, 40, 80),
-- Furniture
(11, 'MAIN', 8, 1, 3, 5),
(12, 'MAIN', 12, 2, 4, 6),
(13, 'MAIN', 35, 5, 10, 20),
(14, 'MAIN', 28, 4, 10, 15),
-- Books
(15, 'MAIN', 100, 8, 25, 50),
(16, 'MAIN', 95, 7, 25, 50),
(17, 'MAIN', 75, 6, 20, 40),
(18, 'MAIN', 85, 7, 20, 40),
-- Sports
(19, 'MAIN', 60, 5, 15, 30),
(20, 'MAIN', 25, 3, 8, 15);

-- ============================================================================
-- INSERT ORDERS
-- ============================================================================
INSERT INTO orders (customer_id, order_date, shipping_address_id, billing_address_id, order_status, payment_status, payment_method, subtotal, tax_amount, shipping_cost, discount_amount, total_amount) VALUES
(1, '2024-01-15 10:30:00', 1, 2, 'DELIVERED', 'COMPLETED', 'CREDIT_CARD', 2528.99, 221.29, 0.00, 0.00, 2750.28),
(2, '2024-01-20 14:15:00', 3, 4, 'DELIVERED', 'COMPLETED', 'PAYPAL', 1948.00, 170.45, 0.00, 50.00, 2068.45),
(3, '2024-02-05 09:45:00', 5, 6, 'DELIVERED', 'COMPLETED', 'CREDIT_CARD', 109.98, 9.62, 15.00, 0.00, 134.60),
(4, '2024-02-12 16:20:00', 7, 8, 'SHIPPED', 'COMPLETED', 'CREDIT_CARD', 1299.00, 113.66, 50.00, 0.00, 1462.66),
(5, '2024-02-18 11:00:00', 9, 10, 'PROCESSING', 'COMPLETED', 'DEBIT_CARD', 648.99, 56.79, 0.00, 0.00, 705.78),
(6, '2024-03-01 13:30:00', 11, 12, 'CONFIRMED', 'COMPLETED', 'CREDIT_CARD', 39.98, 3.50, 10.00, 0.00, 53.48),
(7, '2024-03-10 10:00:00', 13, 14, 'DELIVERED', 'COMPLETED', 'PAYPAL', 3598.00, 314.83, 0.00, 100.00, 3812.83),
(8, '2024-03-15 15:45:00', 15, 16, 'DELIVERED', 'COMPLETED', 'CREDIT_CARD', 89.98, 7.87, 12.00, 0.00, 109.85),
(9, '2024-04-02 12:15:00', 17, 18, 'SHIPPED', 'COMPLETED', 'CREDIT_CARD', 1348.00, 117.95, 25.00, 0.00, 1490.95),
(10, '2024-04-08 14:30:00', 19, 20, 'PROCESSING', 'COMPLETED', 'DEBIT_CARD', 349.98, 30.62, 0.00, 0.00, 380.60);

-- ============================================================================
-- INSERT ORDER ITEMS
-- ============================================================================
INSERT INTO order_items (order_id, product_id, quantity, unit_price, discount_percent, line_total) VALUES
-- Order 1
(1, 1, 1, 2499.00, 0, 2499.00),
(1, 7, 1, 29.99, 0, 29.99),
-- Order 2
(2, 2, 1, 1899.00, 0, 1899.00),
(2, 6, 1, 249.00, 10, 224.10),
-- Order 3
(3, 7, 2, 29.99, 0, 59.98),
(3, 15, 2, 14.99, 0, 29.98),
(3, 19, 1, 49.99, 50, 25.00),
-- Order 4
(4, 11, 1, 1299.00, 0, 1299.00),
-- Order 5
(5, 3, 1, 1099.00, 0, 1099.00),
(5, 5, 1, 399.00, 0, 399.00),
(5, 13, 1, 89.99, 0, 89.99),
-- Order 6
(6, 17, 1, 24.99, 0, 24.99),
(6, 18, 1, 19.99, 25, 14.99),
-- Order 7
(7, 1, 1, 2499.00, 0, 2499.00),
(7, 4, 1, 1199.00, 0, 1199.00),
-- Order 8
(8, 9, 1, 89.99, 0, 89.99),
-- Order 9
(9, 3, 1, 1099.00, 0, 1099.00),
(9, 6, 1, 249.00, 0, 249.00),
-- Order 10
(10, 20, 1, 299.99, 0, 299.99),
(10, 19, 1, 49.99, 0, 49.99);

-- ============================================================================
-- INSERT REVIEWS
-- ============================================================================
INSERT INTO reviews (product_id, customer_id, order_id, rating, review_title, review_text, is_verified_purchase, helpful_count) VALUES
(1, 1, 1, 5, 'Excellent laptop!', 'The MacBook Pro is amazing. Fast, reliable, and beautiful design.', TRUE, 15),
(2, 2, 2, 4, 'Great performance', 'Dell XPS is solid. Only issue is battery life could be better.', TRUE, 8),
(3, 5, 5, 5, 'Best phone ever', 'iPhone 15 Pro exceeded my expectations. Camera is incredible.', TRUE, 22),
(6, 2, 2, 4, 'Good sound quality', 'AirPods Pro sound great, but a bit pricey.', TRUE, 5),
(11, 4, 4, 5, 'Perfect sofa', 'Very comfortable leather sofa. Great quality for the price.', TRUE, 12),
(7, 3, 3, 3, 'Decent t-shirt', 'Quality is okay, but runs a bit small.', TRUE, 3),
(17, 6, 6, 5, 'Must read!', 'Sapiens is fascinating. Changed my perspective on history.', TRUE, 30),
(9, 8, 8, 4, 'Nice dress', 'Beautiful dress, fits well. Color slightly different from photo.', TRUE, 6),
(3, 9, 9, 5, 'Love it!', 'Switched from Android and couldn''t be happier.', TRUE, 18),
(20, 10, 10, 5, 'Quality dumbbells', 'Solid build, easy to adjust weight. Highly recommend.', TRUE, 10);

-- ============================================================================
-- INSERT PROMOTIONS
-- ============================================================================
INSERT INTO promotions (promotion_code, description, discount_type, discount_value, min_purchase_amount, max_discount_amount, start_date, end_date, usage_limit, usage_count) VALUES
('WELCOME10', 'Welcome discount for new customers', 'PERCENTAGE', 10.00, 50.00, 100.00, '2024-01-01', '2024-12-31', 1000, 25),
('SUMMER20', 'Summer sale 20% off', 'PERCENTAGE', 20.00, 100.00, 200.00, '2024-06-01', '2024-08-31', NULL, 0),
('SAVE50', 'Save $50 on orders over $500', 'FIXED_AMOUNT', 50.00, 500.00, NULL, '2024-01-01', '2024-12-31', NULL, 12),
('FLASH100', 'Flash sale $100 off', 'FIXED_AMOUNT', 100.00, 1000.00, NULL, '2024-03-01', '2024-03-15', 100, 3),
('FREESHIP', 'Free shipping on all orders', 'FIXED_AMOUNT', 15.00, 0.00, 15.00, '2024-01-01', '2024-12-31', NULL, 45);

-- ============================================================================
-- INSERT ORDER PROMOTIONS
-- ============================================================================
INSERT INTO order_promotions (order_id, promotion_id, discount_applied) VALUES
(2, 3, 50.00),
(7, 4, 100.00);

-- ============================================================================
-- Summary of inserted data
-- ============================================================================
SELECT 'Data insertion completed!' as status;

SELECT 
    'product_categories' as table_name,
    COUNT(*) as record_count
FROM product_categories
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'customers', COUNT(*) FROM customers
UNION ALL
SELECT 'addresses', COUNT(*) FROM addresses
UNION ALL
SELECT 'inventory', COUNT(*) FROM inventory
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL
SELECT 'reviews', COUNT(*) FROM reviews
UNION ALL
SELECT 'promotions', COUNT(*) FROM promotions
ORDER BY table_name;


