-- ============================================================================
-- Database Creation Script
-- ============================================================================
-- Competency: Creates and modifies database objects
-- Description: Creates the main database for the e-commerce analytics platform
-- ============================================================================

-- Drop database if exists (for development/testing)
DROP DATABASE IF EXISTS ecommerce_analytics;

-- Create database with proper encoding
CREATE DATABASE ecommerce_analytics
    WITH 
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    TEMPLATE = template0;

-- Connect to the database
\c ecommerce_analytics;

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


