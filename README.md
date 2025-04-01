# Odoo Self-Hosted Kit

A complete solution for self-hosting multiple Odoo instances with PostgreSQL and Nginx Proxy Manager using Docker Compose.

## Overview

This kit provides a ready-to-use configuration for running multiple Odoo instances with a shared PostgreSQL database and Nginx Proxy Manager for handling SSL and reverse proxy. It's designed for development, testing, or production environments where you need to run separate Odoo instances.

## Features

- Multiple Odoo instances (currently configured with 2 instances)
- Shared PostgreSQL database
- Nginx Proxy Manager for SSL/TLS termination and reverse proxy
- Persistent storage for all components
- Automatic database initialization
- Health checks for PostgreSQL
- Network isolation
- Custom addons support
- Separate configuration for each Odoo instance
- Management script for easy administration

## Prerequisites

- Docker and Docker Compose installed
- Sufficient disk space for Odoo, PostgreSQL, and Nginx data
- Available ports as configured in the .env file (default: 80, 81, 443, 7001, 7002, 5432)

## Directory Structure

The kit uses the following directory structure for persistent data:

- `/storage/pg_data`: PostgreSQL data
- `/storage/nginx_data`: Nginx configuration data
- `/storage/letsencrypt`: Let's Encrypt certificates
- `/storage/letsencrypt/data`: Let's Encrypt data
- `/storage/odoo/odoo1/data`: Data for first Odoo instance
- `/storage/odoo/odoo1/config`: Configuration for first Odoo instance
- `/storage/odoo/odoo1/extra-addons`: Custom addons for first Odoo instance
- `/storage/odoo/odoo2/data`: Data for second Odoo instance
- `/storage/odoo/odoo2/config`: Configuration for second Odoo instance
- `/storage/odoo/odoo2/extra-addons`: Custom addons for second Odoo instance

Ensure these directories exist and have appropriate permissions before starting the services:

```bash
sudo mkdir -p /storage/pg_data
sudo mkdir -p /storage/nginx_data
sudo mkdir -p /storage/letsencrypt/data
sudo mkdir -p /storage/odoo/odoo1/data /storage/odoo/odoo1/config /storage/odoo/odoo1/extra-addons
sudo mkdir -p /storage/odoo/odoo2/data /storage/odoo/odoo2/config /storage/odoo/odoo2/extra-addons
sudo chmod -R 777 /storage
```

## Configuration

1. Create a `.env` file in the root directory (or copy from `.env.sample`):
   ```
   # PostgreSQL Configuration
   POSTGRES_USER=odoo_user
   POSTGRES_PASSWORD=your_secure_password
   POSTGRESDB=postgres
   POSTGRES_PORT=5432
   
   # Odoo Configuration
   
   # Odoo 1
   ODOO1_INSTANCE_NAME=odoo_instance_1
   ODOO1_PORT=7001
   ODOO1_DB=odoo_db1
   
   # Odoo 2
   ODOO2_INSTANCE_NAME=odoo_instance_2
   ODOO2_PORT=7002
   ODOO2_DB=odoo_db2
   ```

2. Customize the `docker-compose.yml` file if needed:
   - Change ports
   - Add additional Odoo instances
   - Modify volume paths

## Usage

### Starting the Services

```bash
docker compose up -d
```

### Using the Management Script

The kit includes an `odoo-manager.sh` script that helps with common management tasks:

```bash
# Check the status of all services
./odoo-manager.sh check

# Initialize the databases
./odoo-manager.sh init

# Restart Odoo services
./odoo-manager.sh restart

# Show the status of all services
./odoo-manager.sh status

# Display help
./odoo-manager.sh help
```

### Accessing Odoo Instances

- First Odoo instance: http://localhost:7001
- Second Odoo instance: http://localhost:7002

### Accessing Nginx Proxy Manager

- Admin interface: http://localhost:81
- Default login: admin@example.com / changeme

### Stopping the Services

```bash
docker compose down
```

## Database Management

- The PostgreSQL server is accessible on port 5432 (or as configured in .env)
- Databases are automatically created based on the configuration in odoo-manager.sh
- Each Odoo instance is configured to use its respective database

## Custom Addons

To add custom modules to your Odoo instances:

1. Place your custom modules in the respective extra-addons directory:
   - First instance: `/storage/odoo/odoo1/extra-addons`
   - Second instance: `/storage/odoo/odoo2/extra-addons`

2. Restart the Odoo service or update the module list from the Odoo Apps menu

## Adding More Odoo Instances

To add more Odoo instances:

1. Update the `odoo-manager.sh` script to include the new instance:
   ```bash
   ODOO_INSTANCES=(
     "odoo_instance_1:7001:odoo_db1"
     "odoo_instance_2:7002:odoo_db2"
     "odoo_instance_3:7003:odoo_db3"  # New instance
   )
   ```

2. Add the new instance to the `docker-compose.yml` file
3. Add the corresponding environment variables to the `.env` file
4. Create the necessary directories for the new instance
5. Run `docker compose up -d` to apply the changes

## SSL Configuration with Nginx Proxy Manager

1. Access the Nginx Proxy Manager admin interface at http://localhost:81
2. Log in with the default credentials (admin@example.com / changeme)
3. Go to "Proxy Hosts" and add a new proxy host:
   - Domain: your-domain.com
   - Scheme: http
   - Forward Hostname: odoo1 or odoo2 (container name)
   - Forward Port: 8069
   - Enable SSL and configure Let's Encrypt

## Troubleshooting

### Database Initialization Issues

If you encounter database initialization errors:

1. Check if the PostgreSQL container is running properly:
   ```bash
   docker compose logs postgres
   ```

2. Verify that the odoo-manager.sh script has executed successfully by checking the logs

3. Try running the initialization script manually:
   ```bash
   ./odoo-manager.sh init
   ```

4. If the issue persists, try rebuilding and restarting the containers:
   ```bash
   docker compose down
   docker compose up -d --force-recreate
   ```

### Permission Issues

- If you encounter permission issues with volumes, ensure the `/storage` directories have appropriate permissions
- Check container logs with `docker compose logs [service_name]`
- Verify PostgreSQL health with `docker exec postgres_db pg_isready`

### Nginx Proxy Manager Issues

- Check the Nginx Proxy Manager logs:
  ```bash
  docker compose logs nginx
  ```
- Verify that ports 80, 81, and 443 are not in use by other services

## License

See the [LICENSE](LICENSE) file for details.
