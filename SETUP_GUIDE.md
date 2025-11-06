# Quick Setup Guide - E-Commerce Analytics Database

This guide will help you set up the database project for demonstration purposes.

---

## Prerequisites

### 1. Install PostgreSQL

**macOS:**
```bash
# Using Homebrew
brew install postgresql@15
brew services start postgresql@15

# Verify installation
psql --version
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt update
sudo apt install postgresql-15 postgresql-contrib-15
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

**Windows:**
- Download installer from https://www.postgresql.org/download/windows/
- Run installer and follow setup wizard
- Add PostgreSQL bin directory to PATH

### 2. Verify PostgreSQL is Running

```bash
# Check if PostgreSQL is running
psql -U postgres -c "SELECT version();"
```

---

## Quick Start (5 Minutes)

### Step 1: Create the Database

```bash
cd /Users/juan.sanchez/Documents/company/peex/evidences/data_storages

# Create database and basic structure
psql -U postgres -f schema/00_create_database.sql
```

### Step 2: Create Tables and Objects

```bash
# Create all tables
psql -U postgres -d ecommerce_analytics -f schema/01_create_tables.sql

# Create indexes
psql -U postgres -d ecommerce_analytics -f schema/02_create_indexes.sql

# Create views
psql -U postgres -d ecommerce_analytics -f schema/03_create_views.sql

# Create functions
psql -U postgres -d ecommerce_analytics -f schema/04_create_functions.sql
```

### Step 3: Load Sample Data

```bash
# Insert sample data
psql -U postgres -d ecommerce_analytics -f data/insert_sample_data.sql
```

### Step 4: Verify Installation

```bash
# Connect to database
psql -U postgres -d ecommerce_analytics

# Run verification queries
\dt              -- List all tables
\di              -- List all indexes
\dv              -- List all views
SELECT COUNT(*) FROM customers;
SELECT COUNT(*) FROM orders;
SELECT COUNT(*) FROM products;
```

---

## Full Setup (15 Minutes) - Including All Features

### Create All Database Objects

```bash
cd /Users/juan.sanchez/Documents/company/peex/evidences/data_storages

# Execute all schema files
for file in schema/*.sql; do
    echo "Executing $file..."
    psql -U postgres -d ecommerce_analytics -f "$file"
done

# Load data
psql -U postgres -d ecommerce_analytics -f data/insert_sample_data.sql

# Create materialized views
psql -U postgres -d ecommerce_analytics -f optimizations/materialized_views.sql

# Create partitioned tables (optional - for demonstration)
psql -U postgres -d ecommerce_analytics -f optimizations/partitioning.sql
```

---

## Demonstration Scenarios

### Scenario 1: Data Selection Queries (5 minutes)
```bash
psql -U postgres -d ecommerce_analytics -f queries/01_data_selection/basic_queries.sql
```
**Demonstrates:** Basic SELECT statements, WHERE clauses, filtering, pattern matching

### Scenario 2: Ordering and Grouping (5 minutes)
```bash
psql -U postgres -d ecommerce_analytics -f queries/03_ordering_grouping/aggregate_queries.sql
```
**Demonstrates:** GROUP BY, ORDER BY, aggregate functions, window functions

### Scenario 3: Complex Queries (10 minutes)
```bash
psql -U postgres -d ecommerce_analytics -f queries/04_query_optimization/complex_queries.sql
```
**Demonstrates:** JOINs, subqueries, CTEs, UNION operations

### Scenario 4: Database Object Management (5 minutes)
```bash
psql -U postgres -d ecommerce_analytics -f queries/02_database_objects/ddl_examples.sql
```
**Demonstrates:** CREATE, ALTER, DROP statements for various objects

### Scenario 5: Transactions (10 minutes)
```bash
psql -U postgres -d ecommerce_analytics -f transactions/transaction_examples.sql
```
**Demonstrates:** BEGIN/COMMIT/ROLLBACK, ACID properties, isolation levels

### Scenario 6: Performance Optimization (15 minutes)
```bash
# Indexing strategies
psql -U postgres -d ecommerce_analytics -f optimizations/indexing_strategy.sql

# Partitioning
psql -U postgres -d ecommerce_analytics -f optimizations/partitioning.sql

# Materialized views
psql -U postgres -d ecommerce_analytics -f optimizations/materialized_views.sql
```
**Demonstrates:** Various optimization techniques

### Scenario 7: Query Performance Analysis (10 minutes)
```bash
psql -U postgres -d ecommerce_analytics -f performance/query_analysis.sql
psql -U postgres -d ecommerce_analytics -f performance/optimization_comparisons.sql
```
**Demonstrates:** EXPLAIN ANALYZE, performance tuning

---

## Interactive Demo Script

Use this script for a live demonstration:

```sql
-- Connect to database
\c ecommerce_analytics

-- 1. Show database structure
\dt+

-- 2. Simple data selection
SELECT * FROM customers LIMIT 5;

-- 3. Complex analytics query
SELECT 
    c.customer_tier,
    COUNT(DISTINCT c.customer_id) as customers,
    COUNT(DISTINCT o.order_id) as orders,
    ROUND(AVG(o.total_amount), 2) as avg_order_value,
    SUM(o.total_amount) as total_revenue
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_status NOT IN ('CANCELLED', 'REFUNDED')
GROUP BY c.customer_tier
ORDER BY total_revenue DESC;

-- 4. Use a pre-built view
SELECT * FROM v_customer_summary LIMIT 5;

-- 5. Use materialized view for fast analytics
SELECT * FROM mv_product_performance 
ORDER BY total_revenue DESC 
LIMIT 10;

-- 6. Show query optimization with EXPLAIN
EXPLAIN ANALYZE
SELECT p.product_name, COUNT(oi.order_id) as times_ordered
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name
ORDER BY times_ordered DESC
LIMIT 10;

-- 7. Transaction example
BEGIN;
INSERT INTO customers (email, first_name, last_name, customer_tier)
VALUES ('demo@example.com', 'Demo', 'User', 'BRONZE');
SELECT * FROM customers WHERE email = 'demo@example.com';
ROLLBACK;
-- Verify rollback
SELECT * FROM customers WHERE email = 'demo@example.com';
```

---

## Presentation Tips

### For Performance Evaluation

1. **Start with Documentation**
   - Show README.md for project overview
   - Walk through ER diagram in documentation/er_diagram.md
   - Reference data dictionary for detailed specifications

2. **Demonstrate Each Competency**
   
   **Data Selection:**
   ```bash
   psql -d ecommerce_analytics -f queries/01_data_selection/basic_queries.sql | less
   ```
   
   **Creating/Modifying Objects:**
   ```bash
   psql -d ecommerce_analytics -f queries/02_database_objects/ddl_examples.sql | less
   ```
   
   **Ordering/Grouping:**
   ```bash
   psql -d ecommerce_analytics -f queries/03_ordering_grouping/aggregate_queries.sql | less
   ```
   
   **Query Optimization:**
   ```bash
   psql -d ecommerce_analytics -f queries/04_query_optimization/complex_queries.sql | less
   ```
   
   **Transactions:**
   ```bash
   psql -d ecommerce_analytics -f transactions/transaction_examples.sql | less
   ```
   
   **Database Optimization:**
   ```bash
   psql -d ecommerce_analytics -f optimizations/indexing_strategy.sql | less
   psql -d ecommerce_analytics -f optimizations/partitioning.sql | less
   ```
   
   **Documentation:**
   - Open documentation/er_diagram.md
   - Open documentation/data_dictionary.md
   - Open documentation/schema_overview.md
   
   **Performance Analysis:**
   ```bash
   psql -d ecommerce_analytics -f performance/query_analysis.sql | less
   psql -d ecommerce_analytics -f performance/optimization_comparisons.sql | less
   ```

3. **Highlight Key Features**
   - Show the comprehensive schema design (3NF normalization)
   - Demonstrate complex queries with JOINs and CTEs
   - Show EXPLAIN ANALYZE for query optimization
   - Demonstrate transaction isolation levels
   - Show materialized views for performance
   - Display the detailed documentation

---

## Competency Mapping

| Competency | Demonstrated In | Key Files |
|------------|-----------------|-----------|
| Selects data using query language | Data selection queries with filters, joins, subqueries | queries/01_data_selection/basic_queries.sql |
| Creates and modifies database objects | DDL statements for tables, indexes, views, functions | schema/*.sql, queries/02_database_objects/ |
| Orders and groups data | ORDER BY, GROUP BY, aggregates, window functions | queries/03_ordering_grouping/ |
| Combines queries to optimize | JOINs, subqueries, CTEs, UNION | queries/04_query_optimization/ |
| Implements database structure | Complete schema with constraints, indexes | schema/01_create_tables.sql |
| Wraps queries in transactions | BEGIN/COMMIT/ROLLBACK, isolation levels | transactions/transaction_examples.sql |
| Applies optimization techniques | Indexes, partitioning, materialized views | optimizations/ |
| Documents database | ER diagrams, data dictionary, schema docs | documentation/ |
| Optimizes query performance | EXPLAIN ANALYZE, query rewriting | performance/ |

---

## Troubleshooting

### Issue: Connection refused
**Solution:** Ensure PostgreSQL is running
```bash
# macOS
brew services start postgresql@15

# Linux
sudo systemctl start postgresql

# Check status
pg_isready
```

### Issue: Permission denied
**Solution:** Use superuser or grant permissions
```bash
# Connect as superuser
psql -U postgres

# Or grant permissions
GRANT ALL PRIVILEGES ON DATABASE ecommerce_analytics TO your_user;
```

### Issue: Database already exists
**Solution:** Drop and recreate
```bash
psql -U postgres -c "DROP DATABASE IF EXISTS ecommerce_analytics;"
psql -U postgres -f schema/00_create_database.sql
```

### Issue: Tables already exist
**Solution:** Clear database
```bash
psql -U postgres -d ecommerce_analytics -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
```

---

## Clean Up

To remove the entire database:
```bash
psql -U postgres -c "DROP DATABASE IF EXISTS ecommerce_analytics;"
```

---

## Next Steps

1. **Review Documentation**: Start with README.md and documentation/
2. **Run Setup**: Follow Quick Start above
3. **Explore Queries**: Run through demonstration scenarios
4. **Practice**: Modify queries to test your understanding
5. **Present**: Use the demo script for your evaluation

---

## Support Files

- **README.md** - Project overview and structure
- **documentation/** - Complete database documentation
- **schema/** - Database creation scripts
- **queries/** - Query examples for each competency
- **transactions/** - Transaction management examples
- **optimizations/** - Performance optimization techniques
- **performance/** - Query analysis and tuning

---

## Evaluation Checklist

- [ ] Database successfully created
- [ ] All tables, indexes, and objects created
- [ ] Sample data loaded
- [ ] Can demonstrate data selection queries
- [ ] Can show CREATE/ALTER/DROP operations
- [ ] Can demonstrate ORDER BY and GROUP BY
- [ ] Can show complex JOINs and subqueries
- [ ] Can demonstrate transactions with ACID properties
- [ ] Can show optimization techniques (indexes, partitioning)
- [ ] Have complete documentation (ER diagram, data dictionary)
- [ ] Can demonstrate EXPLAIN ANALYZE for performance analysis

---

**Good luck with your performance evaluation!**

This project comprehensively demonstrates all required database storage competencies through practical, real-world examples.


