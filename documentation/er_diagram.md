# E-Commerce Analytics Database - Entity Relationship Diagram

## Database Documentation
**Competency Demonstrated**: Documents information about a database using specialised tools

## Overview
This document provides a comprehensive Entity-Relationship diagram and explanation of the database structure for the E-Commerce Analytics platform.

---

## Entity Relationship Diagram (ERD)

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        E-COMMERCE ANALYTICS DATABASE                     │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────┐
│     CUSTOMERS       │
├─────────────────────┤
│ PK customer_id      │
│    email (UNIQUE)   │
│    first_name       │
│    last_name        │
│    phone            │
│    date_of_birth    │
│    customer_tier    │◄────────────────┐
│    is_active        │                 │
│    created_at       │                 │
│    updated_at       │                 │
└──────────┬──────────┘                 │
           │                            │
           │ 1                          │
           │                            │
           │ N                          │
           │                            │
┌──────────▼──────────┐                 │
│     ADDRESSES       │                 │
├─────────────────────┤                 │
│ PK address_id       │                 │
│ FK customer_id      │                 │
│    address_type     │                 │
│    street_address   │                 │
│    city             │                 │
│    state            │                 │
│    postal_code      │                 │
│    country          │                 │
│    is_default       │                 │
│    created_at       │                 │
└─────────────────────┘                 │
                                        │
┌─────────────────────┐                 │
│       ORDERS        │                 │
├─────────────────────┤                 │
│ PK order_id         │                 │
│ FK customer_id      ├─────────────────┘
│ FK shipping_addr_id │
│ FK billing_addr_id  │
│    order_date       │
│    order_status     │
│    payment_status   │
│    payment_method   │
│    subtotal         │
│    tax_amount       │
│    shipping_cost    │
│    discount_amount  │
│    total_amount     │
│    shipped_at       │
│    delivered_at     │
│    created_at       │
│    updated_at       │
└──────────┬──────────┘
           │
           │ 1
           │
           │ N
           │
┌──────────▼──────────┐        N        ┌─────────────────────┐
│   ORDER_ITEMS       ├────────────────►│     PRODUCTS        │
├─────────────────────┤                 ├─────────────────────┤
│ PK order_item_id    │                 │ PK product_id       │
│ FK order_id         │                 │ FK category_id      │
│ FK product_id       ├─────────────────┤    product_name     │
│    quantity         │                 │    sku (UNIQUE)     │
│    unit_price       │                 │    description      │
│    discount_percent │                 │    unit_price       │
│    line_total       │                 │    cost_price       │
│    created_at       │                 │    weight_kg        │
└─────────────────────┘                 │    is_active        │
                                        │    created_at       │
                                        │    updated_at       │
┌─────────────────────┐                 └──────────┬──────────┘
│      REVIEWS        │                            │
├─────────────────────┤                            │ N
│ PK review_id        │                            │
│ FK product_id       ├────────────────────────────┤
│ FK customer_id      │                            │ 1
│ FK order_id         │                            │
│    rating           │                 ┌──────────▼──────────┐
│    review_title     │                 │ PRODUCT_CATEGORIES  │
│    review_text      │                 ├─────────────────────┤
│    is_verified      │                 │ PK category_id      │
│    helpful_count    │                 │ FK parent_category  │◄──┐
│    created_at       │                 │    category_name    │   │
│    updated_at       │                 │    description      │   │ Self-
└─────────────────────┘                 │    created_at       │───┘ Reference
                                        └─────────────────────┘

┌─────────────────────┐                 ┌─────────────────────┐
│     INVENTORY       │                 │    PROMOTIONS       │
├─────────────────────┤                 ├─────────────────────┤
│ PK inventory_id     │                 │ PK promotion_id     │
│ FK product_id       ├─────────────────┤    promotion_code   │
│    warehouse_loc    │                 │    description      │
│    qty_available    │                 │    discount_type    │
│    qty_reserved     │                 │    discount_value   │
│    reorder_level    │                 │    min_purchase     │
│    reorder_quantity │                 │    max_discount     │
│    last_restocked   │                 │    start_date       │
│    created_at       │                 │    end_date         │
│    updated_at       │                 │    usage_limit      │
└─────────────────────┘                 │    usage_count      │
                                        │    is_active        │
                                        │    created_at       │
                                        └──────────┬──────────┘
                                                   │
                                                   │ N
                                                   │
                                                   │ N
                                                   │
┌─────────────────────┐                 ┌──────────▼──────────┐
│    AUDIT_LOG        │                 │ ORDER_PROMOTIONS    │
├─────────────────────┤                 ├─────────────────────┤
│ PK audit_id         │                 │ PK order_id         │
│    table_name       │                 │ PK promotion_id     │
│    record_id        │                 │    discount_applied │
│    action           │                 │    applied_at       │
│    old_values       │                 └─────────────────────┘
│    new_values       │
│    changed_by       │
│    changed_at       │
└─────────────────────┘
```

---

## Entity Descriptions

### Core Entities

#### CUSTOMERS
Primary entity representing registered users of the e-commerce platform.
- **Primary Key**: `customer_id`
- **Unique Constraints**: `email`
- **Business Rules**:
  - Email must be valid format
  - Customer tier: BRONZE, SILVER, GOLD, PLATINUM
  - Date of birth must be in the past

#### ORDERS
Represents customer purchase transactions.
- **Primary Key**: `order_id`
- **Foreign Keys**: `customer_id`, `shipping_address_id`, `billing_address_id`
- **Business Rules**:
  - Total amount = subtotal + tax + shipping - discount
  - Order status: PENDING → CONFIRMED → PROCESSING → SHIPPED → DELIVERED
  - Payment status: PENDING, COMPLETED, FAILED, REFUNDED

#### PRODUCTS
Catalog of items available for purchase.
- **Primary Key**: `product_id`
- **Foreign Keys**: `category_id`
- **Unique Constraints**: `sku`
- **Business Rules**:
  - Unit price must be >= cost price
  - All prices must be non-negative

### Relationship Entities

#### ORDER_ITEMS
Junction table linking orders to products (many-to-many).
- Stores quantity, price, and discount for each product in an order
- **Business Rule**: `line_total = quantity * unit_price * (1 - discount_percent/100)`

#### ORDER_PROMOTIONS
Junction table linking orders to promotions (many-to-many).
- Tracks which promotions were applied to which orders
- Records the actual discount amount applied

### Supporting Entities

#### ADDRESSES
Stores customer shipping and billing addresses.
- One customer can have multiple addresses
- Address types: SHIPPING, BILLING
- One address can be marked as default

#### PRODUCT_CATEGORIES
Hierarchical categorization of products.
- Self-referencing for parent-child relationships
- Supports unlimited depth of subcategories

#### INVENTORY
Tracks product stock levels across warehouse locations.
- Separates available vs. reserved quantities
- Includes reorder levels for automated restocking alerts

#### REVIEWS
Customer product reviews and ratings.
- Rating scale: 1-5
- Links to specific order for verified purchase tracking
- Includes helpful count for community moderation

#### PROMOTIONS
Discount codes and promotional campaigns.
- Supports percentage and fixed amount discounts
- Includes usage limits and date ranges
- Tracks usage count

#### AUDIT_LOG
Comprehensive audit trail for data changes.
- Stores old and new values in JSONB format
- Tracks who made changes and when
- Action types: INSERT, UPDATE, DELETE

---

## Relationship Cardinalities

| From Entity | Relationship | To Entity | Cardinality | Description |
|-------------|--------------|-----------|-------------|-------------|
| CUSTOMERS | places | ORDERS | 1:N | One customer can place many orders |
| CUSTOMERS | has | ADDRESSES | 1:N | One customer can have multiple addresses |
| CUSTOMERS | writes | REVIEWS | 1:N | One customer can write many reviews |
| ORDERS | contains | ORDER_ITEMS | 1:N | One order contains many items |
| ORDERS | uses | ADDRESSES | N:1 | Many orders can use same address |
| ORDERS | applies | PROMOTIONS | N:N | Orders can have multiple promotions |
| PRODUCTS | belongs to | PRODUCT_CATEGORIES | N:1 | Many products in one category |
| PRODUCTS | has | INVENTORY | 1:N | One product in multiple warehouses |
| PRODUCTS | receives | REVIEWS | 1:N | One product can have many reviews |
| PRODUCTS | in | ORDER_ITEMS | 1:N | One product in many order items |
| PRODUCT_CATEGORIES | contains | PRODUCT_CATEGORIES | 1:N | Hierarchical self-reference |

---

## Referential Integrity

### Cascade Rules

#### ON DELETE CASCADE
- `addresses.customer_id` → When customer deleted, their addresses are deleted
- `order_items.order_id` → When order deleted, order items are deleted
- `order_promotions.order_id` → When order deleted, promotion links are deleted

#### ON DELETE SET NULL
- `product_categories.parent_category_id` → When parent category deleted, child becomes top-level

#### ON DELETE RESTRICT (Default)
- `orders.customer_id` → Cannot delete customer with orders (maintains history)
- `order_items.product_id` → Cannot delete product that has been ordered

---

## Constraints Summary

### Check Constraints
- Email format validation
- Date validations (DOB < current date, resolved_at > submitted_at)
- Enumerated values (customer_tier, order_status, payment_status)
- Numeric ranges (rating 1-5, priority 1-5)
- Business logic (unit_price >= cost_price, total_amount calculation)

### Unique Constraints
- `customers.email`
- `products.sku`
- `promotions.promotion_code`
- `inventory(product_id, warehouse_location)`
- `reviews(product_id, customer_id, order_id)`

### Foreign Key Constraints
All foreign keys are indexed for optimal join performance.

---

## Index Strategy

### Primary Indexes
- All primary keys have automatic B-tree indexes

### Foreign Key Indexes
- All foreign key columns are indexed for join performance

### Business Logic Indexes
- Customer email for login lookups
- Product SKU for catalog searches
- Order date for reporting queries
- Order status for operational queries
- Full-text search on product names/descriptions

### Composite Indexes
- `(customer_id, order_date)` for customer order history
- `(product_id, warehouse_location)` for inventory lookups
- `(order_status, order_date)` for fulfillment queries

### Partial Indexes
- Active customers only
- Non-cancelled orders
- Low stock items
- Open customer feedback

---

## ER Diagram Tools Used

This documentation can be used with:
- **dbdiagram.io** - Online ERD tool
- **DBeaver** - Database management with ER diagram generation
- **pgAdmin** - PostgreSQL admin tool with ERD capabilities
- **draw.io** - General diagramming tool
- **Lucidchart** - Professional diagramming software

---

## Database Normalization

The database follows **Third Normal Form (3NF)**:

1. **1NF**: All tables have primary keys, and all columns contain atomic values
2. **2NF**: No partial dependencies; all non-key attributes depend on entire primary key
3. **3NF**: No transitive dependencies; non-key attributes depend only on primary key

### Denormalization Considerations
Certain calculated fields are stored for performance:
- `orders.total_amount` (calculated but stored for query performance)
- `order_items.line_total` (calculated but stored with constraint to ensure accuracy)

These are acceptable trade-offs for read performance in an OLTP system.

---

## Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2024-10 | Database Team | Initial schema design |
| 1.1 | 2024-10 | Database Team | Added customer_feedback table |
| 1.2 | 2024-10 | Database Team | Added audit_log for compliance |

---

## Related Documentation
- [Data Dictionary](./data_dictionary.md) - Detailed column specifications
- [Schema Overview](./schema_overview.md) - High-level architecture
- [Index Strategy](../optimizations/indexing_strategy.sql) - Index implementation details


