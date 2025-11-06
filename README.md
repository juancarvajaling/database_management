# E-Commerce Analytics Database Project

## Project Overview
This project demonstrates comprehensive database management skills through a realistic e-commerce analytics platform. The database tracks customers, products, orders, inventory, and sales analytics.

## Database System
**PostgreSQL 15+** (can be adapted for MySQL/SQL Server)

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
- Complete schema design with normalization
- Migration scripts for version control
- Database initialization and setup
- Examples in: `schema/migrations/`

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
├── README.md
├── schema/
│   ├── 00_create_database.sql
│   ├── 01_create_tables.sql
│   ├── 02_create_indexes.sql
│   ├── 03_create_views.sql
│   ├── 04_create_functions.sql
│   └── migrations/
├── data/
│   └── insert_sample_data.sql
├── queries/
│   ├── 01_data_selection/
│   ├── 02_database_objects/
│   ├── 03_ordering_grouping/
│   └── 04_query_optimization/
├── transactions/
│   └── transaction_examples.sql
├── optimizations/
│   ├── indexing_strategy.sql
│   ├── partitioning.sql
│   └── materialized_views.sql
├── performance/
│   ├── query_analysis.sql
│   └── optimization_comparisons.sql
└── documentation/
    ├── er_diagram.md
    ├── data_dictionary.md
    └── schema_overview.md
```

## Setup Instructions

### 1. Install PostgreSQL
```bash
# macOS
brew install postgresql@15

# Start PostgreSQL
brew services start postgresql@15
```

### 2. Create Database
```bash
psql postgres -f schema/00_create_database.sql
```

### 3. Initialize Schema
```bash
psql ecommerce_analytics -f schema/01_create_tables.sql
psql ecommerce_analytics -f schema/02_create_indexes.sql
psql ecommerce_analytics -f schema/03_create_views.sql
psql ecommerce_analytics -f schema/04_create_functions.sql
```

### 4. Load Sample Data
```bash
psql ecommerce_analytics -f data/insert_sample_data.sql
```

### 5. Run Example Queries
```bash
# Navigate to any query folder and execute
psql ecommerce_analytics -f queries/01_data_selection/basic_queries.sql
```

## Usage Examples

### Connect to Database
```bash
psql ecommerce_analytics
```

### Run Performance Analysis
```bash
psql ecommerce_analytics -f performance/query_analysis.sql
```

### Test Transactions
```bash
psql ecommerce_analytics -f transactions/transaction_examples.sql
```

## Key Features Demonstrated

- **Normalized database design** (3NF) with proper relationships
- **Complex queries** with joins, subqueries, and CTEs
- **Transaction management** ensuring data consistency
- **Performance optimization** with indexes and query tuning
- **Analytics capabilities** with window functions and aggregations
- **Data integrity** with constraints and triggers
- **Comprehensive documentation** with diagrams and data dictionary

## Technologies Used
- PostgreSQL 15+
- SQL (DDL, DML, DCL, TCL)
- Database design patterns
- Performance analysis tools

## Learning Outcomes
This project demonstrates proficiency in:
- Database design and normalization
- Complex SQL query writing
- Performance optimization techniques
- Transaction management
- Database documentation
- Query analysis and optimization

---
**Created for Performance Evaluation - Data Storage Competency**


