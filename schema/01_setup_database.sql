-- ============================================================================
-- Database Setup for Docker
-- ============================================================================
-- This runs after Docker creates the ecommerce_analytics database
-- Sets up schemas and extensions
-- ============================================================================

-- Create schema for organizing database objects
CREATE SCHEMA IF NOT EXISTS analytics;
CREATE SCHEMA IF NOT EXISTS sales;
CREATE SCHEMA IF NOT EXISTS inventory;

-- Set search path
SET search_path TO public, analytics, sales, inventory;

-- Create extension for UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create extension for cryptographic functions
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Display database information
SELECT 
    current_database() as database_name,
    current_user as connected_user,
    version() as postgresql_version;

COMMENT ON DATABASE ecommerce_analytics IS 'E-commerce analytics platform database demonstrating comprehensive SQL and database management skills';


