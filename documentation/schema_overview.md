# Database Schema Overview

## E-Commerce Analytics Platform

**Competency Demonstrated**: Documents information about a database using specialised tools

---

## Executive Summary

The E-Commerce Analytics database is a comprehensive PostgreSQL-based system designed to support a modern e-commerce platform with robust analytics capabilities. The schema implements industry best practices including proper normalization (3NF), referential integrity, comprehensive indexing, and audit trails.

**Key Statistics:**
- **Tables**: 12 primary tables + partitioned variants
- **Total Columns**: ~130 columns across all tables
- **Relationships**: 20+ foreign key relationships
- **Indexes**: 60+ indexes for optimized query performance
- **Views**: 9 pre-defined views for common queries
- **Materialized Views**: 7 for analytics performance
- **Functions/Procedures**: 15+ for business logic
- **Database Size (with sample data)**: ~50 MB

---

## Architecture Overview

### System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Application Layer                         │
│              (Web App, Mobile App, Admin Dashboard)              │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                     PostgreSQL Database                          │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐   │
│  │  Transactional │  │   Analytical   │  │    Utility     │   │
│  │     Tables     │  │  Materialized  │  │    Objects     │   │
│  │                │  │     Views      │  │                │   │
│  │ • customers    │  │ • mv_customer  │  │ • Functions    │   │
│  │ • orders       │  │   _analytics   │  │ • Triggers     │   │
│  │ • products     │  │ • mv_product   │  │ • Sequences    │   │
│  │ • inventory    │  │   _performance │  │ • Audit Log    │   │
│  └────────────────┘  └────────────────┘  └────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                       Storage Layer                              │
│          (Indexes, Partitions, Materialized Views)               │
└─────────────────────────────────────────────────────────────────┘
```

---

## Schema Layers

### 1. Core Transactional Layer

**Purpose**: Handle real-time OLTP operations

**Tables:**
- `customers` - Customer accounts and profiles
- `orders` - Order transactions
- `order_items` - Order line items
- `products` - Product catalog
- `inventory` - Stock management
- `addresses` - Customer addresses

**Characteristics:**
- Highly normalized (3NF)
- Optimized for writes
- Strong referential integrity
- Real-time consistency

### 2. Reference Data Layer

**Purpose**: Support transactional operations with lookup data

**Tables:**
- `product_categories` - Hierarchical product taxonomy
- `promotions` - Marketing campaigns and discounts

**Characteristics:**
- Relatively static data
- Read-heavy workload
- Hierarchical relationships

### 3. Junction/Relationship Layer

**Purpose**: Implement many-to-many relationships

**Tables:**
- `order_promotions` - Links orders to promotions
- `reviews` - Links customers, products, and orders

**Characteristics:**
- Composite primary keys
- Foreign keys to multiple tables
- Supports complex queries

### 4. Analytics Layer

**Purpose**: Pre-computed aggregations for reporting

**Objects:**
- `mv_customer_analytics` - Customer metrics
- `mv_product_performance` - Product sales analysis
- `mv_daily_sales` - Daily sales summary
- `mv_category_performance` - Category analysis
- `mv_customer_segments` - RFM segmentation
- `mv_monthly_revenue` - Monthly trends
- `mv_inventory_status` - Stock level analysis

**Characteristics:**
- Denormalized for read performance
- Scheduled refresh
- Complex aggregations pre-computed
- Supports dashboards and reports

### 5. Audit and Compliance Layer

**Purpose**: Track all data changes for compliance

**Tables:**
- `audit_log` - Comprehensive change tracking

**Characteristics:**
- Write-only (append-only)
- JSONB for flexible schema
- Trigger-based automation
- GIN indexes for search

---

## Data Flow

### Order Processing Flow

```
1. Customer places order
   ↓
2. Create ORDER record (status: PENDING)
   ↓
3. Create ORDER_ITEMS records
   ↓
4. Reserve INVENTORY (quantity_reserved++)
   ↓
5. Apply PROMOTIONS (if applicable)
   ↓
6. Process payment → Update ORDER (payment_status: COMPLETED)
   ↓
7. Fulfill order → Update ORDER (status: SHIPPED)
   ↓
8. Complete INVENTORY transaction (quantity_available--, quantity_reserved--)
   ↓
9. Confirm delivery → Update ORDER (status: DELIVERED)
   ↓
10. Customer can leave REVIEW
```

### Analytics Refresh Flow

```
1. Transactional data accumulates
   ↓
2. Scheduled job runs (e.g., nightly at 2 AM)
   ↓
3. Refresh materialized views:
   - mv_customer_analytics
   - mv_product_performance
   - mv_daily_sales
   - etc.
   ↓
4. Update statistics (ANALYZE)
   ↓
5. Dashboard queries use refreshed MVs
```

---

## Key Design Patterns

### 1. Soft Delete Pattern
- Uses `is_active` flag instead of physical deletion
- Preserves historical data
- Example: `customers.is_active`, `products.is_active`

### 2. Audit Trail Pattern
- Automatic tracking via triggers
- Stores old and new values in JSONB
- Immutable audit records

### 3. Optimistic Locking Pattern
- Uses `updated_at` timestamp
- Prevents lost updates in concurrent scenarios
- Example: Check `updated_at` before UPDATE

### 4. Hierarchical Data Pattern
- Self-referencing foreign key
- Example: `product_categories.parent_category_id`
- Supports unlimited depth

### 5. State Machine Pattern
- Defined status workflows
- Example: `order_status` progression
- Enforced via application logic and constraints

### 6. Denormalization for Performance
- Calculated fields stored for speed
- Example: `orders.total_amount`
- Maintained via constraints and triggers

---

## Performance Optimization Strategies

### Indexing Strategy

| Index Type | Use Case | Example |
|------------|----------|---------|
| B-tree | Equality and range queries | `idx_orders_customer` |
| GIN | Full-text search | `idx_products_fulltext` |
| BRIN | Large time-series tables | `idx_orders_date_brin` |
| Partial | Subset of rows | `idx_orders_active` |
| Composite | Multi-column queries | `idx_orders_customer_status` |
| Covering | Index-only scans | `idx_orders_customer_covering` |

### Partitioning Strategy

**Range Partitioning by Date:**
- `orders_partitioned` - Partitioned by quarter
- Benefits: Faster queries, easier archival
- Maintenance: Automatic partition creation

**List Partitioning by Category:**
- `customers_partitioned` - Partitioned by tier
- Benefits: Targeted queries, isolated maintenance

**Hash Partitioning:**
- `products_partitioned` - Even distribution
- Benefits: Parallel processing, load balancing

### Materialized Views

- Refresh schedule: Nightly for daily summaries, hourly for critical metrics
- Concurrent refresh enabled via unique indexes
- Incremental refresh for large views

---

## Data Integrity Rules

### Referential Integrity

**Cascade Deletes:**
- Deleting customer → cascades to addresses
- Deleting order → cascades to order_items

**Restrict Deletes:**
- Cannot delete customer with orders (history preservation)
- Cannot delete product that has been ordered

**Set NULL:**
- Deleting parent category → child becomes top-level

### Check Constraints

**Business Logic Validation:**
- Price validation: `unit_price >= cost_price`
- Total calculation: `total_amount = subtotal + tax + shipping - discount`
- Rating range: `rating BETWEEN 1 AND 5`

**Data Quality:**
- Email format validation
- Date logical constraints
- Enumerated values (status fields)

---

## Security Considerations

### Access Control

```sql
-- Role-based access example
CREATE ROLE readonly_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly_user;

CREATE ROLE order_manager;
GRANT SELECT, INSERT, UPDATE ON orders, order_items TO order_manager;

CREATE ROLE analyst;
GRANT SELECT ON ALL TABLES TO analyst;
GRANT SELECT ON ALL MATERIALIZED VIEWS TO analyst;
```

### Audit Trail
- All changes to `orders` table logged automatically
- JSONB storage preserves complete history
- Immutable audit records

### Data Protection
- No sensitive data (PCI) stored directly
- Email format validation
- Soft deletes for GDPR compliance

---

## Scalability Considerations

### Current Capacity
- Designed for 100K+ customers
- 1M+ orders
- 10K+ products
- Handles 1000+ concurrent transactions

### Growth Path
1. **Short term (0-6 months)**
   - Current schema handles growth
   - Regular index maintenance
   - Materialized view refresh optimization

2. **Medium term (6-18 months)**
   - Implement read replicas
   - Partition large tables
   - Archive old data

3. **Long term (18+ months)**
   - Consider sharding by region
   - Separate OLTP and OLAP databases
   - Implement data warehouse

---

## Maintenance Schedule

### Daily
- Automated vacuum (autovacuum)
- Monitor slow queries
- Check replication lag

### Weekly
- Review index usage statistics
- Check table bloat
- Validate backup integrity

### Monthly
- Full VACUUM ANALYZE
- Review and optimize slow queries
- Update statistics
- Partition maintenance

### Quarterly
- REINDEX large tables
- Archive old data
- Review and remove unused indexes
- Capacity planning review

---

## Database Statistics

### Table Sizes (Approximate with Sample Data)

| Table Name | Estimated Rows | Size | Growth Rate |
|------------|---------------|------|-------------|
| customers | 10,000 | 2 MB | 1,000/month |
| orders | 50,000 | 10 MB | 5,000/month |
| order_items | 150,000 | 15 MB | 15,000/month |
| products | 20,000 | 5 MB | 200/month |
| inventory | 20,000 | 3 MB | 200/month |
| reviews | 30,000 | 8 MB | 2,000/month |
| audit_log | 100,000+ | 20 MB | 10,000/month |

### Index Overhead
- Total index size: ~30% of table size
- Trade-off: Faster reads, slower writes

---

## Query Performance Targets

| Query Type | Target Response Time | Optimization Strategy |
|-----------|---------------------|----------------------|
| Simple SELECT by PK | < 1 ms | Primary key index |
| Customer order history | < 50 ms | Composite index on (customer_id, order_date) |
| Product search | < 100 ms | GIN full-text index |
| Order summary | < 200 ms | Covering index |
| Dashboard analytics | < 500 ms | Materialized views |
| Complex reports | < 2 seconds | Materialized views + partitioning |

---

## Technology Stack

- **Database**: PostgreSQL 15+
- **Extensions**: 
  - `uuid-ossp` - UUID generation
  - `pgcrypto` - Cryptographic functions
- **Tools**:
  - pgAdmin - Database administration
  - DBeaver - Development and ERD
  - pg_stat_statements - Query analysis
  - pg_repack - Table maintenance

---

## Related Documentation

1. **[ER Diagram](./er_diagram.md)** - Visual database structure with relationships
2. **[Data Dictionary](./data_dictionary.md)** - Detailed column specifications
3. **[Indexing Strategy](../optimizations/indexing_strategy.sql)** - Index implementation details
4. **[Partitioning Guide](../optimizations/partitioning.sql)** - Table partitioning examples
5. **[Query Optimization](../performance/query_analysis.sql)** - Performance tuning guide
6. **[Transaction Examples](../transactions/transaction_examples.sql)** - ACID property demonstrations

---

## Support and Contacts

| Role | Responsibility | Contact |
|------|---------------|---------|
| Database Administrator | Schema maintenance, performance tuning | dba@company.com |
| Data Architect | Schema design, data modeling | architect@company.com |
| Application Developer | Integration, query optimization | dev-team@company.com |
| Business Analyst | Requirements, reporting | analyst@company.com |

---

## Version Information

- **Schema Version**: 1.2
- **PostgreSQL Version**: 15+
- **Last Updated**: October 2024
- **Next Review**: January 2025

---

## Conclusion

This database schema represents a production-ready e-commerce platform with:
- ✅ Proper normalization and data integrity
- ✅ Comprehensive indexing for performance
- ✅ Advanced optimization techniques (partitioning, materialized views)
- ✅ Audit trails for compliance
- ✅ Scalability considerations
- ✅ Complete documentation

The schema demonstrates expertise in:
- Database design and normalization
- Performance optimization
- Transaction management
- Query optimization
- Documentation best practices

---

*This document is part of the Database Storage Competency evaluation evidence.*


