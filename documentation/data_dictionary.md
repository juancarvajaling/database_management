# Data Dictionary - E-Commerce Analytics Database

## Overview
**Competency Demonstrated**: Documents information about a database using specialised tools

This comprehensive data dictionary documents all tables, columns, data types, constraints, and relationships in the E-Commerce Analytics database.

---

## Table: CUSTOMERS

**Purpose**: Stores customer account information and profile data

**Business Owner**: Customer Service Team  
**Update Frequency**: Real-time  
**Retention Policy**: Indefinite (GDPR compliant deletion on request)

### Columns

| Column Name | Data Type | Nullable | Default | Constraints | Description |
|-------------|-----------|----------|---------|-------------|-------------|
| customer_id | SERIAL | No | AUTO | PRIMARY KEY | Unique customer identifier |
| email | VARCHAR(255) | No | - | UNIQUE, CHECK (email format) | Customer email address, used for login |
| first_name | VARCHAR(100) | No | - | - | Customer's first name |
| last_name | VARCHAR(100) | No | - | - | Customer's last name |
| phone | VARCHAR(20) | Yes | NULL | - | Contact phone number |
| date_of_birth | DATE | Yes | NULL | CHECK (< CURRENT_DATE) | Customer's date of birth for age verification |
| created_at | TIMESTAMP | No | CURRENT_TIMESTAMP | - | Account creation timestamp |
| updated_at | TIMESTAMP | No | CURRENT_TIMESTAMP | - | Last profile update timestamp |
| is_active | BOOLEAN | No | TRUE | - | Account active status flag |
| customer_tier | VARCHAR(20) | No | 'BRONZE' | CHECK (IN enum) | Loyalty tier: BRONZE, SILVER, GOLD, PLATINUM |

### Indexes
- `customers_pkey` (PRIMARY KEY): customer_id
- `idx_customers_email`: email
- `idx_customers_tier`: customer_tier WHERE is_active = TRUE
- `idx_customers_active`: is_active
- `idx_customers_name`: (last_name, first_name)

### Foreign Keys Referenced By
- addresses.customer_id
- orders.customer_id
- reviews.customer_id

### Business Rules
1. Email must be unique and valid format
2. Customer tier automatically updated based on lifetime spending
3. Inactive customers cannot place new orders but history is retained

---

## Table: ADDRESSES

**Purpose**: Stores customer shipping and billing addresses

**Business Owner**: Fulfillment Team  
**Update Frequency**: On-demand by customer

### Columns

| Column Name | Data Type | Nullable | Default | Constraints | Description |
|-------------|-----------|----------|---------|-------------|-------------|
| address_id | SERIAL | No | AUTO | PRIMARY KEY | Unique address identifier |
| customer_id | INTEGER | No | - | FOREIGN KEY → customers | Owner of this address |
| address_type | VARCHAR(20) | No | - | CHECK (IN 'BILLING', 'SHIPPING') | Type of address |
| street_address | VARCHAR(255) | No | - | - | Street address line |
| city | VARCHAR(100) | No | - | - | City name |
| state | VARCHAR(100) | Yes | NULL | - | State or province |
| postal_code | VARCHAR(20) | No | - | - | ZIP or postal code |
| country | VARCHAR(100) | No | 'USA' | - | Country name |
| is_default | BOOLEAN | No | FALSE | - | Default address for type |
| created_at | TIMESTAMP | No | CURRENT_TIMESTAMP | - | Address creation timestamp |

### Indexes
- `addresses_pkey` (PRIMARY KEY): address_id
- `idx_addresses_customer`: customer_id
- `idx_addresses_customer_type`: (customer_id, address_type)
- `idx_addresses_default`: (customer_id, is_default) WHERE is_default = TRUE

---

## Table: PRODUCT_CATEGORIES

**Purpose**: Hierarchical product categorization

**Business Owner**: Merchandising Team  
**Update Frequency**: Monthly

### Columns

| Column Name | Data Type | Nullable | Default | Constraints | Description |
|-------------|-----------|----------|---------|-------------|-------------|
| category_id | SERIAL | No | AUTO | PRIMARY KEY | Unique category identifier |
| category_name | VARCHAR(100) | No | - | UNIQUE | Category display name |
| parent_category_id | INTEGER | Yes | NULL | FOREIGN KEY → product_categories | Parent category for hierarchy |
| description | TEXT | Yes | NULL | - | Category description |
| created_at | TIMESTAMP | No | CURRENT_TIMESTAMP | - | Category creation timestamp |

### Indexes
- `product_categories_pkey` (PRIMARY KEY): category_id
- `idx_categories_parent`: parent_category_id
- `idx_categories_name`: category_name

### Business Rules
1. Top-level categories have NULL parent_category_id
2. Supports unlimited depth of subcategories
3. Cannot delete category with existing products

---

## Table: PRODUCTS

**Purpose**: Product catalog and inventory master data

**Business Owner**: Merchandising Team  
**Update Frequency**: Daily

### Columns

| Column Name | Data Type | Nullable | Default | Constraints | Description |
|-------------|-----------|----------|---------|-------------|-------------|
| product_id | SERIAL | No | AUTO | PRIMARY KEY | Unique product identifier |
| product_name | VARCHAR(255) | No | - | - | Product display name |
| category_id | INTEGER | No | - | FOREIGN KEY → product_categories | Product category |
| sku | VARCHAR(50) | No | - | UNIQUE | Stock Keeping Unit |
| description | TEXT | Yes | NULL | - | Detailed product description |
| unit_price | DECIMAL(10,2) | No | - | CHECK (>= 0), CHECK (>= cost_price) | Retail selling price |
| cost_price | DECIMAL(10,2) | No | - | CHECK (>= 0) | Product cost/wholesale price |
| weight_kg | DECIMAL(8,2) | Yes | NULL | - | Product weight in kilograms |
| is_active | BOOLEAN | No | TRUE | - | Product availability flag |
| created_at | TIMESTAMP | No | CURRENT_TIMESTAMP | - | Product creation timestamp |
| updated_at | TIMESTAMP | No | CURRENT_TIMESTAMP | - | Last update timestamp |

### Indexes
- `products_pkey` (PRIMARY KEY): product_id
- `idx_products_category`: category_id WHERE is_active = TRUE
- `idx_products_sku`: sku
- `idx_products_price`: unit_price
- `idx_products_search` (GIN): to_tsvector('english', product_name || ' ' || description)
- `idx_products_active_category`: (category_id, is_active, unit_price)

### Business Rules
1. SKU must be unique across all products
2. Unit price must be greater than or equal to cost price
3. Inactive products cannot be added to new orders

---

## Table: INVENTORY

**Purpose**: Product stock levels across warehouse locations

**Business Owner**: Warehouse Team  
**Update Frequency**: Real-time

### Columns

| Column Name | Data Type | Nullable | Default | Constraints | Description |
|-------------|-----------|----------|---------|-------------|-------------|
| inventory_id | SERIAL | No | AUTO | PRIMARY KEY | Unique inventory record identifier |
| product_id | INTEGER | No | - | FOREIGN KEY → products | Product being tracked |
| warehouse_location | VARCHAR(100) | No | - | - | Warehouse location code |
| quantity_available | INTEGER | No | 0 | CHECK (>= 0), CHECK (>= quantity_reserved) | Total units in stock |
| quantity_reserved | INTEGER | No | 0 | CHECK (>= 0) | Units reserved for orders |
| reorder_level | INTEGER | No | 10 | - | Trigger point for reordering |
| reorder_quantity | INTEGER | No | 50 | - | Quantity to order when restocking |
| last_restocked_at | TIMESTAMP | Yes | NULL | - | Last restock timestamp |
| created_at | TIMESTAMP | No | CURRENT_TIMESTAMP | - | Record creation timestamp |
| updated_at | TIMESTAMP | No | CURRENT_TIMESTAMP | - | Last update timestamp |

### Indexes
- `inventory_pkey` (PRIMARY KEY): inventory_id
- `idx_inventory_product`: product_id
- `idx_inventory_warehouse`: warehouse_location
- `idx_inventory_low_stock`: (product_id, warehouse_location) WHERE quantity_available <= reorder_level
- `idx_inventory_availability`: (product_id, warehouse_location, quantity_available)

### Unique Constraints
- UNIQUE (product_id, warehouse_location)

### Business Rules
1. quantity_reserved cannot exceed quantity_available
2. System triggers reorder alerts when quantity_available <= reorder_level
3. Reserved quantities are locked for specific orders

---

## Table: ORDERS

**Purpose**: Customer purchase transactions

**Business Owner**: Order Management Team  
**Update Frequency**: Real-time

### Columns

| Column Name | Data Type | Nullable | Default | Constraints | Description |
|-------------|-----------|----------|---------|-------------|-------------|
| order_id | SERIAL | No | AUTO | PRIMARY KEY | Unique order identifier |
| customer_id | INTEGER | No | - | FOREIGN KEY → customers | Customer placing order |
| order_date | TIMESTAMP | No | CURRENT_TIMESTAMP | - | Order placement timestamp |
| shipping_address_id | INTEGER | No | - | FOREIGN KEY → addresses | Shipping address |
| billing_address_id | INTEGER | No | - | FOREIGN KEY → addresses | Billing address |
| order_status | VARCHAR(20) | No | 'PENDING' | CHECK (IN enum) | PENDING, CONFIRMED, PROCESSING, SHIPPED, DELIVERED, CANCELLED, REFUNDED |
| payment_status | VARCHAR(20) | No | 'PENDING' | CHECK (IN enum) | PENDING, COMPLETED, FAILED, REFUNDED |
| payment_method | VARCHAR(50) | Yes | NULL | - | Payment method used |
| subtotal | DECIMAL(10,2) | No | - | CHECK (>= 0) | Sum of order items before tax/fees |
| tax_amount | DECIMAL(10,2) | No | 0 | CHECK (>= 0) | Sales tax amount |
| shipping_cost | DECIMAL(10,2) | No | 0 | CHECK (>= 0) | Shipping and handling fee |
| discount_amount | DECIMAL(10,2) | No | 0 | CHECK (>= 0) | Total discounts applied |
| total_amount | DECIMAL(10,2) | No | - | CHECK (= subtotal + tax + shipping - discount) | Final order total |
| shipped_at | TIMESTAMP | Yes | NULL | - | Shipment timestamp |
| delivered_at | TIMESTAMP | Yes | NULL | - | Delivery confirmation timestamp |
| created_at | TIMESTAMP | No | CURRENT_TIMESTAMP | - | Record creation timestamp |
| updated_at | TIMESTAMP | No | CURRENT_TIMESTAMP | - | Last update timestamp |

### Indexes
- `orders_pkey` (PRIMARY KEY): order_id
- `idx_orders_customer`: (customer_id, order_date DESC)
- `idx_orders_status`: (order_status, order_date)
- `idx_orders_payment`: payment_status
- `idx_orders_date`: order_date DESC
- `idx_orders_fulfillment`: (order_status, shipped_at, delivered_at)
- `idx_orders_recent`: created_at DESC WHERE order_status != 'CANCELLED'

### Business Rules
1. total_amount must equal subtotal + tax_amount + shipping_cost - discount_amount
2. Order status follows workflow: PENDING → CONFIRMED → PROCESSING → SHIPPED → DELIVERED
3. Payment must be COMPLETED before order can be shipped

---

## Table: ORDER_ITEMS

**Purpose**: Individual line items within orders

**Business Owner**: Order Management Team  
**Update Frequency**: Real-time (insert-only)

### Columns

| Column Name | Data Type | Nullable | Default | Constraints | Description |
|-------------|-----------|----------|---------|-------------|-------------|
| order_item_id | SERIAL | No | AUTO | PRIMARY KEY | Unique order item identifier |
| order_id | INTEGER | No | - | FOREIGN KEY → orders (CASCADE) | Parent order |
| product_id | INTEGER | No | - | FOREIGN KEY → products | Product ordered |
| quantity | INTEGER | No | - | CHECK (> 0) | Number of units ordered |
| unit_price | DECIMAL(10,2) | No | - | CHECK (>= 0) | Price per unit at time of order |
| discount_percent | DECIMAL(5,2) | No | 0 | CHECK (>= 0 AND <= 100) | Discount percentage applied |
| line_total | DECIMAL(10,2) | No | - | CHECK (= quantity * unit_price * (1 - discount_percent/100)) | Total for this line item |
| created_at | TIMESTAMP | No | CURRENT_TIMESTAMP | - | Record creation timestamp |

### Indexes
- `order_items_pkey` (PRIMARY KEY): order_item_id
- `idx_order_items_order`: order_id
- `idx_order_items_product`: product_id
- `idx_order_items_product_price`: (product_id, unit_price, quantity)

### Business Rules
1. line_total must equal quantity * unit_price * (1 - discount_percent / 100)
2. unit_price is captured at time of order (historical pricing)
3. Cannot be modified after order confirmation

---

## Table: REVIEWS

**Purpose**: Customer product reviews and ratings

**Business Owner**: Customer Experience Team  
**Update Frequency**: Real-time

### Columns

| Column Name | Data Type | Nullable | Default | Constraints | Description |
|-------------|-----------|----------|---------|-------------|-------------|
| review_id | SERIAL | No | AUTO | PRIMARY KEY | Unique review identifier |
| product_id | INTEGER | No | - | FOREIGN KEY → products | Product being reviewed |
| customer_id | INTEGER | No | - | FOREIGN KEY → customers | Reviewer |
| order_id | INTEGER | No | - | FOREIGN KEY → orders | Verified purchase order |
| rating | INTEGER | No | - | CHECK (BETWEEN 1 AND 5) | Star rating (1-5) |
| review_title | VARCHAR(200) | Yes | NULL | - | Review headline |
| review_text | TEXT | Yes | NULL | - | Review content |
| is_verified_purchase | BOOLEAN | No | TRUE | - | Verified purchase flag |
| helpful_count | INTEGER | No | 0 | CHECK (>= 0) | Helpful votes count |
| created_at | TIMESTAMP | No | CURRENT_TIMESTAMP | - | Review submission timestamp |
| updated_at | TIMESTAMP | No | CURRENT_TIMESTAMP | - | Last edit timestamp |

### Indexes
- `reviews_pkey` (PRIMARY KEY): review_id
- `idx_reviews_product`: (product_id, created_at DESC)
- `idx_reviews_customer`: customer_id
- `idx_reviews_rating`: (rating, created_at DESC)
- `idx_reviews_verified`: (product_id, is_verified_purchase) WHERE is_verified_purchase = TRUE
- `idx_reviews_helpful`: helpful_count DESC WHERE helpful_count > 0

### Unique Constraints
- UNIQUE (product_id, customer_id, order_id)

### Business Rules
1. Customers can only review products they've purchased
2. One review per customer per product per order
3. Rating must be between 1 and 5 stars

---

## Table: PROMOTIONS

**Purpose**: Promotional codes and discount campaigns

**Business Owner**: Marketing Team  
**Update Frequency**: On-demand

### Columns

| Column Name | Data Type | Nullable | Default | Constraints | Description |
|-------------|-----------|----------|---------|-------------|-------------|
| promotion_id | SERIAL | No | AUTO | PRIMARY KEY | Unique promotion identifier |
| promotion_code | VARCHAR(50) | No | - | UNIQUE | Promotional code string |
| description | TEXT | Yes | NULL | - | Promotion description |
| discount_type | VARCHAR(20) | No | - | CHECK (IN 'PERCENTAGE', 'FIXED_AMOUNT') | Type of discount |
| discount_value | DECIMAL(10,2) | No | - | CHECK (> 0) | Discount value (percent or amount) |
| min_purchase_amount | DECIMAL(10,2) | No | 0 | - | Minimum order subtotal required |
| max_discount_amount | DECIMAL(10,2) | Yes | NULL | - | Maximum discount cap |
| start_date | TIMESTAMP | No | - | CHECK (< end_date) | Promotion start date |
| end_date | TIMESTAMP | No | - | - | Promotion expiration date |
| usage_limit | INTEGER | Yes | NULL | - | Maximum number of uses |
| usage_count | INTEGER | No | 0 | CHECK (<= usage_limit OR usage_limit IS NULL) | Current usage count |
| is_active | BOOLEAN | No | TRUE | - | Active status flag |
| created_at | TIMESTAMP | No | CURRENT_TIMESTAMP | - | Promotion creation timestamp |

### Indexes
- `promotions_pkey` (PRIMARY KEY): promotion_id
- `idx_promotions_code`: promotion_code
- `idx_promotions_active`: (start_date, end_date) WHERE is_active = TRUE
- `idx_promotions_expiry`: end_date WHERE is_active = TRUE AND end_date > CURRENT_TIMESTAMP

### Business Rules
1. Promotion codes must be unique
2. end_date must be after start_date
3. usage_count cannot exceed usage_limit (if set)

---

## Table: ORDER_PROMOTIONS

**Purpose**: Links orders to applied promotions (many-to-many)

**Business Owner**: Order Management Team  
**Update Frequency**: Real-time

### Columns

| Column Name | Data Type | Nullable | Default | Constraints | Description |
|-------------|-----------|----------|---------|-------------|-------------|
| order_id | INTEGER | No | - | PRIMARY KEY, FOREIGN KEY → orders (CASCADE) | Order receiving discount |
| promotion_id | INTEGER | No | - | PRIMARY KEY, FOREIGN KEY → promotions | Promotion applied |
| discount_applied | DECIMAL(10,2) | No | - | - | Actual discount amount |
| applied_at | TIMESTAMP | No | CURRENT_TIMESTAMP | - | Application timestamp |

### Indexes
- PRIMARY KEY: (order_id, promotion_id)

---

## Table: AUDIT_LOG

**Purpose**: Comprehensive audit trail for data changes

**Business Owner**: Compliance Team  
**Update Frequency**: Automated (trigger-based)

### Columns

| Column Name | Data Type | Nullable | Default | Constraints | Description |
|-------------|-----------|----------|---------|-------------|-------------|
| audit_id | SERIAL | No | AUTO | PRIMARY KEY | Unique audit entry identifier |
| table_name | VARCHAR(100) | No | - | - | Table that was modified |
| record_id | INTEGER | No | - | - | ID of modified record |
| action | VARCHAR(20) | No | - | CHECK (IN 'INSERT', 'UPDATE', 'DELETE') | Type of operation |
| old_values | JSONB | Yes | NULL | - | Previous record values (UPDATE/DELETE) |
| new_values | JSONB | Yes | NULL | - | New record values (INSERT/UPDATE) |
| changed_by | VARCHAR(100) | Yes | NULL | - | User/process making change |
| changed_at | TIMESTAMP | No | CURRENT_TIMESTAMP | - | Change timestamp |

### Indexes
- `audit_log_pkey` (PRIMARY KEY): audit_id
- `idx_audit_table`: (table_name, changed_at DESC)
- `idx_audit_record`: (table_name, record_id, changed_at DESC)
- `idx_audit_recent`: changed_at DESC
- `idx_audit_new_values` (GIN): new_values
- `idx_audit_old_values` (GIN): old_values

---

## Data Types Reference

| PostgreSQL Type | Description | Example Values |
|----------------|-------------|----------------|
| SERIAL | Auto-incrementing integer | 1, 2, 3, ... |
| INTEGER | 4-byte signed integer | -2147483648 to +2147483647 |
| VARCHAR(n) | Variable-length string | 'text', 'abc@email.com' |
| TEXT | Unlimited length string | Long descriptions |
| DECIMAL(p,s) | Exact numeric | 99.99, 1234.56 |
| DATE | Calendar date | '2024-01-15' |
| TIMESTAMP | Date and time | '2024-01-15 14:30:00' |
| BOOLEAN | True/False | TRUE, FALSE |
| JSONB | Binary JSON | '{"key": "value"}' |

---

## Glossary

- **SKU**: Stock Keeping Unit - unique product identifier
- **OLTP**: Online Transaction Processing
- **3NF**: Third Normal Form - database normalization level
- **GIN Index**: Generalized Inverted Index - for full-text search
- **BRIN Index**: Block Range Index - for large sorted tables
- **Cascade**: Automatically propagate deletes to related records
- **Constraint**: Database rule enforcing data integrity
- **Foreign Key**: Column referencing primary key of another table

---

## Change Log

| Date | Version | Author | Changes |
|------|---------|--------|---------|
| 2024-10 | 1.0 | Database Team | Initial data dictionary |
| 2024-10 | 1.1 | Database Team | Added customer_feedback table |
| 2024-10 | 1.2 | Database Team | Enhanced audit_log documentation |

---

## Related Documents
- [ER Diagram](./er_diagram.md) - Visual database structure
- [Schema Overview](./schema_overview.md) - High-level architecture
- [Index Strategy](../optimizations/indexing_strategy.sql) - Indexing details


