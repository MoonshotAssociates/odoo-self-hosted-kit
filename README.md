# Odoo Self-Hosted Kit

A complete solution for self-hosting multiple Odoo instances with PostgreSQL using Docker Compose.

## Overview

This kit provides a ready-to-use configuration for running multiple Odoo instances with a shared PostgreSQL database. It's designed for development, testing, or production environments where you need to run separate Odoo instances.

## Features

- Multiple Odoo instances (currently configured with 2 instances)
- Shared PostgreSQL database
- Persistent storage for both Odoo and PostgreSQL data
- Automatic database initialization
- Health checks for PostgreSQL
- Network isolation
- Custom addons support
- Separate configuration for each Odoo instance

## Prerequisites

- Docker and Docker Compose installed
- Sufficient disk space for Odoo and PostgreSQL data
- Ports 7001, 7002, and 5432 available on your host

## Directory Structure

The kit uses the following directory structure for persistent data:

- `/storage/pg_data`: PostgreSQL data
- `/storage/odoo/odoo1/data`: Data for first Odoo instance
- `/storage/odoo/odoo1/config`: Configuration for first Odoo instance
- `/storage/odoo/odoo1/extra-addons`: Custom addons for first Odoo instance
- `/storage/odoo/odoo2/data`: Data for second Odoo instance
- `/storage/odoo/odoo2/config`: Configuration for second Odoo instance
- `/storage/odoo/odoo2/extra-addons`: Custom addons for second Odoo instance

Ensure these directories exist and have appropriate permissions before starting the services:

```bash
sudo mkdir -p /storage/pg_data
sudo mkdir -p /storage/odoo/odoo1/data /storage/odoo/odoo1/config /storage/odoo/odoo1/extra-addons
sudo mkdir -p /storage/odoo/odoo2/data /storage/odoo/odoo2/config /storage/odoo/odoo2/extra-addons
sudo chmod -R 777 /storage
```

## Configuration

1. Create a `.env` file in the root directory with the following variables:
   ```
   POSTGRES_USER=your_postgres_username
   POSTGRES_PASSWORD=your_secure_password
   POSTGRESDB=postgres
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

### Managing Odoo with the Consolidated Script

This kit includes a comprehensive management script (`odoo-manager.sh`) that handles all aspects of Odoo management:

```bash
# Make the script executable
chmod +x odoo-manager.sh

# Check services, databases, and web interfaces
sudo ./odoo-manager.sh check

# Prepare databases for initialization
sudo ./odoo-manager.sh init

# Restart Odoo services
sudo ./odoo-manager.sh restart

# Show the status of all services
sudo ./odoo-manager.sh status

# Display help
sudo ./odoo-manager.sh help
```

The script automatically:
- Verifies Docker and service status
- Checks if databases exist and creates them if needed
- Tests web interface accessibility
- Provides initialization instructions

#### Adding More Odoo Instances

To add more Odoo instances:

1. Update the `ODOO_INSTANCES` array in `odoo-manager.sh`:
   ```bash
   ODOO_INSTANCES=(
     "odoo_instance_1:7001:odoo_db1"
     "odoo_instance_2:7002:odoo_db2"
     "odoo_instance_3:7003:odoo_db3"  # New instance
   )
   ```

2. Add the corresponding service configuration in `docker-compose.yml`

### Accessing Odoo Instances

- First Odoo instance: http://localhost:7001
- Second Odoo instance: http://localhost:7002

### Stopping the Services

```bash
docker compose down
```

## Database Management

- The PostgreSQL server is accessible on port 5432
- Two databases are automatically created: `odoo_db1` and `odoo_db2`
- Each Odoo instance is configured to use its respective database

## Custom Addons

To add custom modules to your Odoo instances:

1. Place your custom modules in the respective extra-addons directory:
   - First instance: `/storage/odoo/odoo1/extra-addons`
   - Second instance: `/storage/odoo/odoo2/extra-addons`

2. Restart the Odoo service or update the module list from the Odoo Apps menu

## Troubleshooting

### Database Initialization Issues

If you encounter database initialization errors like:
```
ERROR odoo.modules.loading: Database not initialized, you can force it with `-i base`
```

The docker-compose.yml file has been configured to use the `-i base` parameter with additional options to force initialization. This ensures that each Odoo instance properly initializes its database with the base module.

If you still encounter issues:

1. Run the check command to verify services and databases:
   ```bash
   sudo ./odoo-manager.sh check
   ```

2. Try restarting the Odoo services:
   ```bash
   sudo ./odoo-manager.sh restart
   ```

3. Check container logs:
   ```bash
   docker logs odoo_instance_1
   docker logs odoo_instance_2
   ```

4. If the issue persists, try rebuilding and restarting the containers:
   ```bash
   docker compose down
   docker compose up -d --force-recreate
   ```

### Permission Issues

- If you encounter permission issues with volumes, ensure the `/storage` directories have appropriate permissions
- Check container logs with `docker-compose logs [service_name]`
- Verify PostgreSQL health with `docker exec postgres_db pg_isready`

## License

See the [LICENSE](LICENSE) file for details.
