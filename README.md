# E-Commerce Analytics Database Project

## Project Overview
This project demonstrates comprehensive database management skills through a realistic e-commerce analytics platform. The database tracks customers, products, orders, inventory, and sales analytics using PostgreSQL 15.

## Key Competencies Demonstrated

### 1. Data Selection Using Query Language
- Basic SELECT statements with various filtering conditions
- Complex data retrieval with multiple conditions
- Date range queries and pattern matching
- Examples in: `queries/01_data_selection/`

### 2. Database Object Creation and Modification
- Table creation with proper data types
- Constraints (PRIMARY KEY, FOREIGN KEY, UNIQUE, CHECK)
- Views, stored procedures, and functions
- ALTER statements for schema modifications
- Examples in: `schema/` and `queries/02_database_objects/`

### 3. Data Ordering and Grouping
- ORDER BY with multiple columns and directions
- GROUP BY with aggregate functions (COUNT, SUM, AVG, MAX, MIN)
- HAVING clauses for filtered aggregations
- Window functions for advanced analytics
- Examples in: `queries/03_ordering_grouping/`

### 4. Query Optimization Through Combination
- Subqueries (correlated and non-correlated)
- Common Table Expressions (CTEs)
- JOIN operations (INNER, LEFT, RIGHT, FULL)
- Query refactoring for performance
- Examples in: `queries/04_query_optimization/`

### 5. Database Structure Implementation
- Complete schema design with normalization (3NF)
- Migration scripts for version control
- Database initialization and setup
- Examples in: `schema/`

### 6. Transaction Management
- ACID property demonstrations
- Transaction isolation levels
- Concurrent transaction handling
- Rollback and commit scenarios
- Examples in: `transactions/`

### 7. Database Optimization Techniques
- Index creation and analysis
- Table partitioning
- Query execution plan analysis
- Materialized views
- Examples in: `optimizations/`

### 8. Database Documentation
- ER diagrams and schema documentation
- Data dictionary
- Index documentation
- Stored procedure documentation
- See: `documentation/`

### 9. Query Performance Optimization
- EXPLAIN and EXPLAIN ANALYZE usage
- Query rewriting techniques
- Performance benchmarking
- Before/after optimization comparisons
- Examples in: `performance/`

## Project Structure
```
data_storages/
├── README.md                          # This file
├── SHOWCASE.md                        # Competency demonstrations
├── docker-compose.yml                 # Docker orchestration
├── Dockerfile                         # PostgreSQL container definition
├── docker/                            # Docker configuration
│   ├── postgresql.conf               # PostgreSQL settings
│   └── pgadmin-servers.json          # pgAdmin pre-configuration
├── schema/                            # Database schema
│   ├── 01_setup_database.sql         # Database, schemas, and extensions
│   ├── 02_create_tables.sql          # Table definitions
│   ├── 03_create_indexes.sql         # Index definitions
│   ├── 04_create_views.sql           # View definitions
│   └── 05_create_functions.sql       # Functions and triggers
├── data/
│   └── insert_sample_data.sql        # Sample data
├── queries/
│   ├── 01_data_selection/            # SELECT query examples
│   ├── 02_database_objects/          # DDL examples
│   ├── 03_ordering_grouping/         # Aggregation examples
│   └── 04_query_optimization/        # Complex query examples
├── transactions/
│   └── transaction_examples.sql      # Transaction management examples
├── optimizations/
│   ├── indexing_strategy.sql         # Indexing techniques
│   ├── partitioning.sql              # Table partitioning
│   └── materialized_views.sql        # Materialized views
├── performance/
│   ├── query_analysis.sql            # EXPLAIN examples
│   └── optimization_comparisons.sql  # Before/after optimization
└── documentation/
    ├── er_diagram.md                 # ER diagram and relationships
    ├── erd.png                       # ER diagram image
    ├── data_dictionary.md            # Complete data dictionary
    └── schema_overview.md            # Architecture documentation
```

## 🚀 Quick Start with Docker

### Prerequisites
- Docker Desktop installed ([download here](https://www.docker.com/products/docker-desktop))

### Start the Database

```bash
# Navigate to project directory
cd /path/to/data_storages

# Start PostgreSQL and pgAdmin
docker-compose up -d

# Wait ~30 seconds for initialization
```

That's it! The database will be automatically created with all tables, indexes, views, and sample data.

### Access the Database

**🌐 pgAdmin (Recommended)**
1. Open browser: http://localhost:8080
2. Login:
   - Email: `admin@admin.com`
   - Password: `admin`
3. Server is pre-configured and connected!

**Connection Details** (for other SQL clients):
- Host: `localhost`
- Port: `5432`
- Database: `ecommerce_analytics`
- Username: `postgres`
- Password: `postgres`

## 📊 Using pgAdmin

### Explore the Database

1. **View Tables**: 
   - Servers → E-Commerce Analytics DB → Databases → ecommerce_analytics → Schemas → public → Tables

2. **Run Queries**:
   - Right-click on `ecommerce_analytics` → Query Tool
   - Copy queries from `queries/` folder

3. **View ER Diagram**:
   - Right-click on `ecommerce_analytics` → ERD For Database

4. **Check Data**:
   - Right-click on any table → View/Edit Data → All Rows

### Example Queries to Try

**Simple data selection:**
```sql
SELECT * FROM customers LIMIT 5;
SELECT * FROM products WHERE unit_price > 100;
```

**Analytics query:**
```sql
SELECT 
    c.customer_tier,
    COUNT(*) as customer_count,
    SUM(o.total_amount) as total_revenue
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_status = 'DELIVERED'
GROUP BY c.customer_tier
ORDER BY total_revenue DESC;
```

**Use a view:**
```sql
SELECT * FROM v_customer_summary ORDER BY lifetime_value DESC LIMIT 10;
```

**Performance analysis:**
```sql
EXPLAIN ANALYZE
SELECT p.product_name, COUNT(oi.order_id) as times_ordered
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name
ORDER BY times_ordered DESC;
```

## 📁 Query Examples

All query examples are in the `queries/` folder. Open these files in pgAdmin's Query Tool:

- **Data Selection**: `queries/01_data_selection/basic_queries.sql`
- **Database Objects**: `queries/02_database_objects/ddl_examples.sql`
- **Ordering & Grouping**: `queries/03_ordering_grouping/aggregate_queries.sql`
- **Complex Queries**: `queries/04_query_optimization/complex_queries.sql`
- **Transactions**: `transactions/transaction_examples.sql`
- **Performance**: `performance/query_analysis.sql`

## 🛠 Docker Commands

```bash
# Start containers
docker-compose up -d

# Stop containers (keeps data)
docker-compose stop

# Stop and remove containers (keeps data)
docker-compose down

# Remove everything including data (fresh start)
docker-compose down -v

# View logs
docker-compose logs -f postgres

# Check status
docker-compose ps
```

## 🔄 Reset Database

To start fresh with a clean database:

```bash
docker-compose down -v
docker-compose up -d
```

Wait ~30 seconds for reinitialization.

## 📖 Documentation

- **[SHOWCASE.md](./SHOWCASE.md)** - Competency demonstrations with code examples
- **[documentation/er_diagram.md](./documentation/er_diagram.md)** - Database ER diagram
- **[documentation/erd.png](./documentation/erd.png)** - ER diagram image
- **[documentation/data_dictionary.md](./documentation/data_dictionary.md)** - Complete data dictionary
- **[documentation/schema_overview.md](./documentation/schema_overview.md)** - Architecture overview

## 🎯 Key Features

- ✅ **Normalized database design** (3NF) with proper relationships
- ✅ **60+ indexes** for optimal query performance
- ✅ **Complex queries** with joins, subqueries, and CTEs
- ✅ **Transaction management** ensuring data consistency
- ✅ **Performance optimization** with indexes and query tuning
- ✅ **Analytics capabilities** with window functions and aggregations
- ✅ **Data integrity** with constraints and triggers
- ✅ **Comprehensive documentation** with diagrams and data dictionary
- ✅ **Docker containerized** - runs anywhere, no PostgreSQL installation needed
- ✅ **pgAdmin included** - web-based database management interface

## 🔧 Technologies Used

- PostgreSQL 15
- Docker & Docker Compose
- pgAdmin 4
- SQL (DDL, DML, DCL, TCL)

---
