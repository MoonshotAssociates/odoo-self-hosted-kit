#!/bin/bash
set -e

# This script serves as a custom entrypoint for Odoo containers
# It checks if the database exists before initializing it

# Get the database name from environment variable
DB_NAME=$DATABASE

# Function to check if database exists
database_exists() {
  local db_name=$1
  # Use psql to check if the database exists
  PGPASSWORD=$PASSWORD psql -h $HOST -U $USER -d postgres -t -c "SELECT 1 FROM pg_database WHERE datname='$db_name'" | grep -q 1
  return $?
}

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL..."
until PGPASSWORD=$PASSWORD psql -h $HOST -U $USER -d postgres -c '\q'; do
  echo "PostgreSQL is unavailable - sleeping"
  sleep 1
done

echo "PostgreSQL is up - checking if database $DB_NAME exists"

# Check if the database exists
if database_exists "$DB_NAME"; then
  echo "Database $DB_NAME already exists, skipping initialization"
  # Start Odoo without initialization parameters
  exec odoo "$@"
else
  echo "Database $DB_NAME does not exist, initializing..."
  # Start Odoo with initialization parameters
  exec odoo "$@" -d "$DB_NAME" -i base --without-demo=all
fi
