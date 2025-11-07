# E-Commerce Analytics Database - Docker Image
# PostgreSQL 15 with pre-configured database and sample data

FROM postgres:15-alpine

# Set environment variables
ENV POSTGRES_USER=postgres
ENV POSTGRES_PASSWORD=postgres
ENV POSTGRES_DB=ecommerce_analytics
ENV PGDATA=/var/lib/postgresql/data

# Install postgresql client tools
RUN apk add --no-cache postgresql-client

# Create directory for initialization scripts
RUN mkdir -p /docker-entrypoint-initdb.d

# Copy all SQL files to initialization directory
# Files in /docker-entrypoint-initdb.d are executed in alphabetical order
# Note: Docker will auto-create ecommerce_analytics DB from POSTGRES_DB env var
COPY schema/01_setup_database.sql /docker-entrypoint-initdb.d/01-setup-database.sql
COPY schema/02_create_tables.sql /docker-entrypoint-initdb.d/02-create-tables.sql
COPY schema/03_create_indexes.sql /docker-entrypoint-initdb.d/03-create-indexes.sql
COPY schema/04_create_views.sql /docker-entrypoint-initdb.d/04-create-views.sql
COPY schema/05_create_functions.sql /docker-entrypoint-initdb.d/05-create-functions.sql
COPY data/insert_sample_data.sql /docker-entrypoint-initdb.d/06-insert-sample-data.sql
COPY optimizations/materialized_views.sql /docker-entrypoint-initdb.d/07-create-materialized-views.sql

# Copy query files for easy access. Keep original schema files for manual setup reference
COPY schema/ /sql/schema/
COPY queries/ /sql/queries/
COPY transactions/ /sql/transactions/
COPY optimizations/ /sql/optimizations/
COPY performance/ /sql/performance/
COPY documentation/ /sql/documentation/

# Expose PostgreSQL port
EXPOSE 5432

# Health check
HEALTHCHECK --interval=10s --timeout=5s --start-period=30s --retries=5 \
    CMD pg_isready -U postgres -d ecommerce_analytics || exit 1

# Labels for documentation
LABEL maintainer="Database Team"
LABEL description="E-Commerce Analytics Database with PostgreSQL 15"
LABEL version="1.0"
LABEL project="data-storage-competency"

# The base image already has the correct ENTRYPOINT and CMD
# ENTRYPOINT ["docker-entrypoint.sh"]
# CMD ["postgres"]

