# Setup Guide - E-Commerce Analytics Database

This guide explains how to set up and use the database project.

---

## 🐳 Docker Setup (Recommended)

**The easiest and fastest way to run this project!**

### Why Docker?
- ✅ No PostgreSQL installation required
- ✅ Works on all platforms (macOS, Linux, Windows)
- ✅ Setup in under 3 minutes
- ✅ Includes pgAdmin web interface
- ✅ Easy cleanup

### Quick Start

```bash
cd /path/to/data_storages

# Start everything
docker-compose up -d

# Wait ~30 seconds for initialization
```

**That's it! 🎉** Database is ready with all data loaded.

### Access Methods

**pgAdmin Web Interface (Recommended):**
- URL: http://localhost:8080
- Email: `admin@admin.com`
- Password: `admin`

**External SQL Client:**
- Host: `localhost`
- Port: `5432`
- Database: `ecommerce_analytics`
- Username: `postgres`
- Password: `postgres`

**Command Line:**
```bash
docker exec -it ecommerce_analytics_db psql -U postgres -d ecommerce_analytics
```

### Docker Commands

```bash
# Start containers
docker-compose up -d

# Stop containers (keeps data)
docker-compose stop

# Remove everything (fresh start)
docker-compose down -v

# View logs
docker-compose logs -f postgres

# Check status
docker-compose ps
```

---

## Alternative: Manual PostgreSQL Installation

If you prefer installing PostgreSQL directly on your system:

### Prerequisites

#### 1. Install PostgreSQL 15+

**macOS:**
```bash
brew install postgresql@15
brew services start postgresql@15
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt update
sudo apt install postgresql-15 postgresql-contrib-15
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

**Windows:**
- Download from https://www.postgresql.org/download/windows/
- Run installer and follow setup wizard
- Add PostgreSQL bin directory to PATH

#### 2. Verify Installation

```bash
psql --version
psql -U postgres -c "SELECT version();"
```

### Database Setup

#### Step 1: Create Database and Setup

```bash
cd /path/to/data_storages

# Create database with schemas and extensions
psql -U postgres -f schema/01_setup_database.sql
```

#### Step 2: Create Tables

```bash
psql -U postgres -d ecommerce_analytics -f schema/02_create_tables.sql
```

#### Step 3: Create Indexes

```bash
psql -U postgres -d ecommerce_analytics -f schema/03_create_indexes.sql
```

#### Step 4: Create Views

```bash
psql -U postgres -d ecommerce_analytics -f schema/04_create_views.sql
```

#### Step 5: Create Functions

```bash
psql -U postgres -d ecommerce_analytics -f schema/05_create_functions.sql
```

#### Step 6: Load Sample Data

```bash
psql -U postgres -d ecommerce_analytics -f data/insert_sample_data.sql
```

#### Step 7: Create Materialized Views (Optional)

```bash
psql -U postgres -d ecommerce_analytics -f optimizations/create_materialized_views.sql
```

### Verify Installation

```bash
# Connect to database
psql -U postgres -d ecommerce_analytics

# Check tables
\dt

# Check data
SELECT COUNT(*) FROM customers;
SELECT COUNT(*) FROM orders;
SELECT COUNT(*) FROM products;

# Exit
\q
```

---

## 📊 Using the Database

### With pgAdmin (Docker or Desktop)

1. **Open pgAdmin**: http://localhost:8080 (Docker) or pgAdmin Desktop
2. **Connect to Server**:
   - Host: `localhost` (or `postgres` if in Docker network)
   - Port: `5432`
   - Database: `ecommerce_analytics`
   - Username: `postgres`
   - Password: `postgres`
3. **Navigate**: Servers → Database → Schemas → public → Tables
4. **Run Queries**: Right-click database → Query Tool

### With Command Line (psql)

```bash
# Connect
psql -U postgres -d ecommerce_analytics

# Common commands
\dt              -- List tables
\di              -- List indexes
\dv              -- List views
\df              -- List functions
\d table_name    -- Describe table
\q               -- Quit
```

### Running Example Queries

**Option 1: In pgAdmin**
- Open Query Tool
- Click Open File (📁)
- Select file from `queries/` folder
- Execute (⚡ or F5)

**Option 2: From Command Line**
```bash
psql -U postgres -d ecommerce_analytics -f queries/01_data_selection/basic_queries.sql
```

---

## 🎯 Demo Scenarios

### Scenario 1: Data Selection Queries
**File**: `queries/01_data_selection/basic_queries.sql`  
**Demonstrates**: Basic SELECT, WHERE, filtering, pattern matching

### Scenario 2: Ordering and Grouping
**File**: `queries/03_ordering_grouping/aggregate_queries.sql`  
**Demonstrates**: GROUP BY, ORDER BY, aggregate functions, window functions

### Scenario 3: Complex Queries
**File**: `queries/04_query_optimization/complex_queries.sql`  
**Demonstrates**: JOINs, subqueries, CTEs, UNION operations

### Scenario 4: Database Object Management
**File**: `queries/02_database_objects/ddl_examples.sql`  
**Demonstrates**: CREATE, ALTER, DROP statements

### Scenario 5: Transactions
**File**: `transactions/transaction_examples.sql`  
**Demonstrates**: BEGIN/COMMIT/ROLLBACK, ACID properties, isolation levels

### Scenario 6: Performance Optimization
**Files**: 
- `optimizations/indexing_strategy.sql`
- `optimizations/partitioning.sql`
- `optimizations/create_materialized_views.sql`

**Demonstrates**: Indexing strategies, partitioning, materialized views

### Scenario 7: Query Performance Analysis
**Files**:
- `performance/query_analysis.sql`
- `performance/optimization_comparisons.sql`

**Demonstrates**: EXPLAIN ANALYZE, performance tuning

---

## 📚 Example Queries

### Simple Queries

```sql
-- View all customers
SELECT * FROM customers LIMIT 10;

-- Find gold tier customers
SELECT * FROM customers WHERE customer_tier = 'GOLD';

-- Products over $500
SELECT * FROM products WHERE unit_price > 500 ORDER BY unit_price DESC;
```

### Analytics Queries

```sql
-- Customer lifetime value
SELECT 
    customer_tier,
    COUNT(*) as customers,
    ROUND(AVG(lifetime_value), 2) as avg_lifetime_value
FROM v_customer_summary
GROUP BY customer_tier
ORDER BY avg_lifetime_value DESC;

-- Top selling products
SELECT * FROM mv_product_performance 
ORDER BY total_revenue DESC 
LIMIT 10;

-- Daily sales trend
SELECT * FROM mv_daily_sales 
ORDER BY sale_date DESC 
LIMIT 30;
```

### Complex Queries

```sql
-- Customer order analysis
SELECT 
    c.first_name || ' ' || c.last_name as customer,
    COUNT(o.order_id) as order_count,
    SUM(o.total_amount) as total_spent,
    AVG(o.total_amount) as avg_order_value
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_status = 'DELIVERED'
GROUP BY c.customer_id, c.first_name, c.last_name
HAVING SUM(o.total_amount) > 1000
ORDER BY total_spent DESC;
```

---

## 🔧 Maintenance

### Update Statistics

```sql
ANALYZE customers;
ANALYZE orders;
ANALYZE products;
```

### Refresh Materialized Views

```sql
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_customer_analytics;
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_product_performance;
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_daily_sales;
```

### Vacuum Database

```sql
VACUUM ANALYZE;
```

### Check Database Size

```sql
SELECT pg_size_pretty(pg_database_size('ecommerce_analytics'));
```

---

## 🐛 Troubleshooting

### Docker Issues

**Port already in use:**
```bash
# Stop local PostgreSQL
brew services stop postgresql

# Or change port in docker-compose.yml
```

**Container won't start:**
```bash
docker-compose logs postgres
docker-compose down -v
docker-compose up -d
```

### Manual Installation Issues

**Cannot connect:**
```bash
# Check if PostgreSQL is running
pg_isready

# Start PostgreSQL
brew services start postgresql  # macOS
sudo systemctl start postgresql # Linux
```

**Permission denied:**
```bash
# Connect as superuser
psql -U postgres

# Grant permissions
GRANT ALL PRIVILEGES ON DATABASE ecommerce_analytics TO your_user;
```

**Database already exists:**
```bash
# Drop and recreate
psql -U postgres -c "DROP DATABASE IF EXISTS ecommerce_analytics;"
psql -U postgres -f schema/01_setup_database.sql
```

---

## 🔄 Reset Database

### Docker
```bash
docker-compose down -v
docker-compose up -d
```

### Manual Installation
```bash
# Drop database
psql -U postgres -c "DROP DATABASE IF EXISTS ecommerce_analytics CASCADE;"

# Recreate
psql -U postgres -f schema/01_setup_database.sql
psql -U postgres -d ecommerce_analytics -f schema/02_create_tables.sql
# ... continue with other schema files
psql -U postgres -d ecommerce_analytics -f data/insert_sample_data.sql
```

---

## 📖 Documentation

- **[README.md](./README.md)** - Project overview
- **[DOCKER_SETUP.md](./DOCKER_SETUP.md)** - Complete Docker guide
- **[documentation/er_diagram.md](./documentation/er_diagram.md)** - ER diagram
- **[documentation/data_dictionary.md](./documentation/data_dictionary.md)** - Data dictionary
- **[documentation/schema_overview.md](./documentation/schema_overview.md)** - Architecture

---

## ✅ Verification Checklist

- [ ] Database successfully created
- [ ] All tables created (12 tables)
- [ ] All indexes created (60+ indexes)
- [ ] All views created (9 views)
- [ ] Materialized views created (7 MVs)
- [ ] Sample data loaded (10 customers, 20 products, 10 orders)
- [ ] Can run SELECT queries successfully
- [ ] Can demonstrate CREATE/ALTER/DROP operations
- [ ] Can show ORDER BY and GROUP BY examples
- [ ] Can execute complex JOINs and subqueries
- [ ] Can demonstrate transactions with ACID properties
- [ ] Can show optimization techniques
- [ ] Complete documentation available
- [ ] Can demonstrate EXPLAIN ANALYZE

---

## 🎓 For Performance Evaluation

**Recommended Approach: Docker + pgAdmin**

1. **Setup** (30 seconds):
   ```bash
   docker-compose up -d
   ```

2. **Access pgAdmin**: http://localhost:8080

3. **Demonstrate competencies** using pgAdmin Query Tool

4. **Show documentation** in `documentation/` folder

5. **Cleanup**:
   ```bash
   docker-compose down
   ```

---

**Good luck with your performance evaluation!**

This project comprehensively demonstrates all required database storage competencies through practical, real-world examples.
