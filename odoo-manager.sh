#!/bin/bash
set -e

# Configuration - Add new instances here
# Format: "instance_name:port:database_name"
ODOO_INSTANCES=(
  "odoo_instance_1:7001:odoo_db1"
  "odoo_instance_2:7002:odoo_db2"
  "odoo_instance_3:7003:odoo_db3"
  # Add more instances as needed, e.g.:
  # "odoo_instance_4:7004:odoo_db4"
)

# PostgreSQL container name
PG_CONTAINER="postgres_db"
PG_USER="root"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to initialize PostgreSQL databases
# This function is called when the script is run as an entrypoint in the PostgreSQL container
initialize_postgres_databases() {
  echo "Running PostgreSQL initialization..."
  
  # Extract database names from ODOO_INSTANCES
  DB_NAMES=()
  for instance_info in "${ODOO_INSTANCES[@]}"; do
    IFS=':' read -r _ _ db_name <<< "$instance_info"
    DB_NAMES+=("$db_name")
  done
  
  # Create databases if they don't exist
  echo "Creating databases..."
  for DB in "${DB_NAMES[@]}"; do
    psql -U "$POSTGRES_USER" <<EOSQL
    CREATE DATABASE $DB OWNER $POSTGRES_USER;
    
    -- Grant all privileges to the user
    GRANT ALL PRIVILEGES ON DATABASE $DB TO $POSTGRES_USER;
EOSQL
    echo "Database $DB created and privileges granted"
  done
  
  echo "All databases created successfully"
  echo "Database setup completed. Odoo will initialize the databases when it starts."
}

# Function to check if Docker is running
check_docker() {
  if ! docker ps > /dev/null 2>&1; then
    echo -e "${RED}Error: Cannot connect to Docker. Make sure Docker is running and you have permission to access it.${NC}"
    echo "Try running this script with sudo: sudo ./odoo-manager.sh"
    exit 1
  fi
}

# Function to check if services are running
check_services() {
  echo -e "${BLUE}Checking Odoo and PostgreSQL services...${NC}"
  
  # Check if PostgreSQL container is running
  if docker ps | grep -q "$PG_CONTAINER"; then
    echo -e "${GREEN}✅ PostgreSQL container is running${NC}"
  else
    echo -e "${YELLOW}❌ PostgreSQL container is not running${NC}"
    echo "Starting services with docker-compose..."
    docker-compose up -d
  fi
  
  # Check if Odoo containers are running
  for instance_info in "${ODOO_INSTANCES[@]}"; do
    IFS=':' read -r instance_name port db_name <<< "$instance_info"
    
    if docker ps | grep -q "$instance_name"; then
      echo -e "${GREEN}✅ $instance_name is running${NC}"
    else
      echo -e "${YELLOW}❌ $instance_name is not running${NC}"
      echo "Starting services with docker-compose..."
      docker-compose up -d
      break
    fi
  done
}

# Function to check and create databases
check_databases() {
  echo -e "${BLUE}Checking databases in PostgreSQL...${NC}"
  DB_LIST=$(docker exec $PG_CONTAINER psql -U $PG_USER -c "SELECT datname FROM pg_database WHERE datistemplate = false;" -t | grep -v "^\s*$")
  
  for instance_info in "${ODOO_INSTANCES[@]}"; do
    IFS=':' read -r instance_name port db_name <<< "$instance_info"
    
    if echo "$DB_LIST" | grep -q "$db_name"; then
      echo -e "${GREEN}✅ Database $db_name exists${NC}"
    else
      echo -e "${YELLOW}❌ Database $db_name does not exist${NC}"
      echo "Creating database $db_name..."
      docker exec $PG_CONTAINER psql -U $PG_USER -c "CREATE DATABASE $db_name OWNER $PG_USER;"
      docker exec $PG_CONTAINER psql -U $PG_USER -c "GRANT ALL PRIVILEGES ON DATABASE $db_name TO $PG_USER;"
      echo -e "${GREEN}Database $db_name created.${NC}"
    fi
  done
}

# Function to check web interfaces
check_web_interfaces() {
  echo ""
  echo -e "${BLUE}Checking Odoo web interfaces...${NC}"
  for instance_info in "${ODOO_INSTANCES[@]}"; do
    IFS=':' read -r instance_name port db_name <<< "$instance_info"
    
    if curl -s --head --fail http://localhost:$port > /dev/null 2>&1; then
      echo -e "${GREEN}✅ $instance_name web interface is accessible at http://localhost:$port${NC}"
    else
      echo -e "${YELLOW}❌ $instance_name web interface is not accessible at http://localhost:$port${NC}"
      echo "   This might be normal if the container just started. Wait a few moments and try again."
    fi
  done
}

# Function to display available services
display_services() {
  echo ""
  echo -e "${BLUE}Odoo services should be available at:${NC}"
  for instance_info in "${ODOO_INSTANCES[@]}"; do
    IFS=':' read -r instance_name port db_name <<< "$instance_info"
    echo -e "- ${GREEN}$instance_name${NC}: http://localhost:$port (database: $db_name)"
  done
}

# Function to display initialization instructions
display_init_instructions() {
  echo ""
  echo -e "${BLUE}To initialize the databases, please:${NC}"
  echo "1. Access the Odoo web interface at one of the URLs above"
  echo "2. You'll see a database creation screen"
  echo "3. Fill in the form with:"
  echo "   - Master Password: your chosen master password"
  echo "   - Database Name: use the corresponding database name (e.g., odoo_db1 for instance 1)"
  echo "   - Email: your admin email"
  echo "   - Password: your admin password"
  echo "   - Language: your preferred language"
  echo "   - Country: your country"
  echo ""
  echo "4. Click 'Create Database' and wait for the initialization to complete"
  echo ""
  echo "Note: If you don't see the database creation screen, the database might already be initialized."
}

# Function to restart services
restart_services() {
  echo -e "${BLUE}Restarting Odoo services...${NC}"
  
  # Build a list of service names
  SERVICE_NAMES=""
  for instance_info in "${ODOO_INSTANCES[@]}"; do
    IFS=':' read -r instance_name _ _ <<< "$instance_info"
    SERVICE_NAMES="$SERVICE_NAMES $instance_name"
  done
  
  # Restart the services
  docker-compose restart $SERVICE_NAMES
  echo -e "${GREEN}Odoo services restarted.${NC}"
}

# Function to display usage
display_usage() {
  echo "Usage: $0 [OPTION]"
  echo "Manage Odoo instances and databases"
  echo ""
  echo "Options:"
  echo "  check      Check services, databases, and web interfaces"
  echo "  init       Prepare databases for initialization"
  echo "  restart    Restart Odoo services"
  echo "  status     Show the status of all services"
  echo "  help       Display this help message"
  echo ""
  echo "Example: $0 check"
}

# Check if this script is being run as an entrypoint in the PostgreSQL container
# This is determined by checking if POSTGRES_PASSWORD environment variable is set
if [ -n "$POSTGRES_PASSWORD" ]; then
  # Running as PostgreSQL container entrypoint
  initialize_postgres_databases
  exit 0
fi

# Main execution for command-line usage
case "$1" in
  check)
    check_docker
    check_services
    check_databases
    check_web_interfaces
    display_services
    display_init_instructions
    ;;
    
  init)
    check_docker
    check_services
    check_databases
    display_services
    display_init_instructions
    ;;
    
  restart)
    check_docker
    restart_services
    ;;
    
  status)
    check_docker
    check_services
    check_web_interfaces
    display_services
    ;;
    
  help|--help|-h)
    display_usage
    ;;
    
  *)
    display_usage
    exit 1
    ;;
esac

exit 0
