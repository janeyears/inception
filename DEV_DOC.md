# Developer Documentation

## Project Overview

Inception is a Docker-based infrastructure project that deploys a WordPress website with a complete LEMP stack (Linux, Nginx, MySQL/MariaDB, PHP). All services run in separate containers built from Alpine Linux base images.

## Architecture

### Service Communication Flow

```
Client (HTTPS) → Nginx (443) → WordPress/PHP-FPM (9000) → MariaDB (3306)
```

### Container Dependencies

- **nginx** depends on **wordpress** (healthcheck-based)
- **wordpress** depends on **mariadb** (healthcheck-based)

### Docker Network

All services communicate through a custom bridge network named `inception` defined in docker-compose.yml. This provides:
- Automatic DNS resolution (services can reach each other by container name)
- Network isolation from other Docker containers
- Internal communication without exposing unnecessary ports to the host

### Data Persistence

Two Docker volumes are used for persistent data:
- `db_data`: MariaDB database files (`/var/lib/mysql`)
- `wp_data`: WordPress files and uploads (`/var/www/html`)

Both volumes are mapped to host directories at `/home/ekashirs/data/` for backup and inspection purposes.

## Services

### 1. Nginx (Reverse Proxy & Web Server)

**Base Image:** Alpine 3.22

**Purpose:** 
- Serves as HTTPS reverse proxy
- Terminates SSL/TLS connections
- Proxies PHP requests to WordPress container via FastCGI

**Key Configuration:**
- Only listens on port 443 (HTTPS)
- TLS 1.2 and 1.3 support
- FastCGI proxying to `wordpress:9000`
- SSL certificates read from Docker secrets

**Files:**
- Dockerfile: `srcs/requirements/nginx/Dockerfile`
- Config: `srcs/requirements/nginx/conf/nginx.conf`

**Build Process:**
1. Install nginx, openssl, bash
2. Remove default site configuration
3. Copy custom nginx.conf
4. Expose port 443

**Runtime:**
- Runs nginx in foreground mode (`daemon off`)
- SSL certificates mounted from `secrets/ssl/`

### 2. WordPress (Application Server)

**Base Image:** Alpine 3.22

**Purpose:**
- Runs PHP-FPM to process PHP code
- Hosts WordPress application
- Manages WordPress installation and configuration

**Key Configuration:**
- PHP-FPM listens on port 9000
- WP-CLI installed for WordPress management
- No web server included (nginx handles HTTP)
- Configured to connect to MariaDB via environment variables

**Files:**
- Dockerfile: `srcs/requirements/wordpress/Dockerfile`
- Setup script: `srcs/requirements/wordpress/tools/setup.sh`

**Build Process:**
1. Install PHP 8.3, PHP-FPM, and required extensions
2. Install MySQL client for database connectivity
3. Install WP-CLI for WordPress management
4. Create PHP-FPM runtime directory
5. Configure PHP memory limit for WP-CLI
6. Copy and prepare setup script

**Runtime:**
The `setup.sh` script:
1. Configures PHP-FPM to listen on all interfaces (0.0.0.0:9000)
2. Downloads WordPress if not already present
3. Creates `wp-config.php` with database credentials
4. Installs WordPress (if fresh) or updates (if existing)
5. Creates admin and regular user accounts
6. Starts PHP-FPM in foreground mode

**Health Check:**
- Checks if PHP-FPM is listening on port 9000 using netcat
- 30 retries with 10s interval
- 90s start period for initialization

### 3. MariaDB (Database Server)

**Base Image:** Alpine 3.22

**Purpose:**
- Provides MySQL-compatible database for WordPress
- Stores all WordPress content (posts, users, settings)

**Key Configuration:**
- Listens on port 3306 (internal network only)
- Custom configuration in `my.cnf`
- Data directory: `/var/lib/mysql`

**Files:**
- Dockerfile: `srcs/requirements/mariadb/Dockerfile`
- Config: `srcs/requirements/mariadb/conf/my.cnf`
- Init script: `srcs/requirements/mariadb/tools/init-db.sh`

**Build Process:**
1. Install MariaDB server and client
2. Create necessary directories with correct permissions
3. Copy custom MariaDB configuration
4. Copy and prepare initialization script

**Runtime:**
The `init-db.sh` script:
1. Reads root and user passwords from Docker secrets
2. Initializes the database (if first run)
3. Creates WordPress database
4. Creates WordPress database user with appropriate privileges
5. Sets root password
6. Removes anonymous users and test databases
7. Starts MariaDB server in foreground mode

**Health Check:**
- Uses `mariadb-admin ping` to verify database is ready
- 20 retries with 10s interval
- 60s start period for initialization

## Security Features

### Docker Secrets

Sensitive data is managed using Docker secrets (mounted as files in `/run/secrets/`):

- `db_password.txt` - WordPress database user password
- `db_root_password.txt` - MariaDB root password
- `wp_admin_password.txt` - WordPress admin password
- `wp_user_password.txt` - WordPress regular user password
- `ssl/cert.pem` - SSL certificate
- `ssl/key.pem` - SSL private key

**Why Secrets?**
- Not exposed in container inspection
- Read from files, not environment variables
- More secure than hardcoding in Dockerfiles or docker-compose.yml

### TLS/SSL

- Only HTTPS traffic accepted (port 443)
- TLS 1.2 and 1.3 support
- No HTTP port 80 exposed
- Self-signed certificates or Let's Encrypt can be used

### Network Isolation

- Services communicate only through internal Docker network
- Only Nginx port 443 exposed to host
- Database and PHP-FPM not accessible from outside

### File Permissions

- MariaDB runs as `mysql` user
- PHP-FPM can run as `nobody` or `www-data`
- Secrets files have restricted permissions (600)

## Environment Variables

Defined in `srcs/.env`:

```bash
# Domain
WP_DOMAIN=ekashirs.42.fr

# WordPress Admin
WP_ADMIN=admin_username
WP_ADMIN_EMAIL=admin@example.com

# WordPress User
WP_USER=regular_user
WP_USER_EMAIL=user@example.com

# Database
MYSQL_DATABASE=wordpress
MYSQL_USER=wp_user
```

**Note:** Passwords are NOT in .env - they're in secrets files.

## Build and Deployment

### Makefile Targets

- `make` or `make all`: Build and start all services
- `make down`: Stop containers (keeps volumes)
- `make clean`: Stop and remove containers
- `make fclean`: Full cleanup (containers, volumes, data directories)
- `make re`: Rebuild everything from scratch

### Build Order

Docker Compose builds services in dependency order:
1. MariaDB (no dependencies)
2. WordPress (waits for MariaDB health check)
3. Nginx (waits for WordPress health check)

### First-Time Setup Steps

1. Create secrets directory and files:
```bash
mkdir -p secrets/ssl
printf 'your_password' > secrets/db_password.txt
printf 'your_root_password' > secrets/db_root_password.txt
printf 'your_admin_password' > secrets/wp_admin_password.txt
printf 'your_user_password' > secrets/wp_user_password.txt
chmod 600 secrets/*.txt
```

2. Generate SSL certificates:
```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout secrets/ssl/key.pem \
  -out secrets/ssl/cert.pem \
  -subj "/CN=ekashirs.42.fr"
```

3. Create and configure `srcs/.env`:
```bash
cp srcs/.env.example srcs/.env
# Edit srcs/.env with your values
```

4. Add domain to `/etc/hosts`:
```bash
echo "127.0.0.1 ekashirs.42.fr" | sudo tee -a /etc/hosts
```

5. Build and run:
```bash
make
```

## Development Workflow

### Viewing Logs

```bash
# All services
docker-compose -f srcs/docker-compose.yml logs -f

# Specific service
docker logs nginx
docker logs wordpress
docker logs mariadb
```

### Accessing Containers

```bash
# Execute commands in running containers
docker exec -it nginx sh
docker exec -it wordpress sh
docker exec -it mariadb sh

# Access MariaDB shell
docker exec -it mariadb mysql -u root -p
```

### Testing Changes

1. Modify configuration files or scripts
2. Rebuild affected service:
```bash
docker-compose -f srcs/docker-compose.yml build nginx
docker-compose -f srcs/docker-compose.yml up -d nginx
```

3. Or rebuild everything:
```bash
make re
```

### Debugging Tips

**Container won't start:**
- Check logs: `docker logs <container_name>`
- Verify secrets files exist and have correct permissions
- Check `.env` file is properly formatted
- Ensure volumes have correct permissions

**Database connection errors:**
- Verify MariaDB is healthy: `docker ps`
- Check database credentials in secrets
- Ensure WordPress is using correct `MYSQL_USER`
- Test connection: `docker exec wordpress mysql -h mariadb -u wp_user -p`

**Nginx 502 Bad Gateway:**
- Verify WordPress/PHP-FPM is running: `docker ps`
- Check PHP-FPM is listening: `docker exec wordpress netstat -tuln | grep 9000`
- Review nginx error logs: `docker logs nginx`

**SSL/Certificate errors:**
- Verify certificate files exist in `secrets/ssl/`
- Check certificate: `openssl x509 -in secrets/ssl/cert.pem -text -noout`
- Ensure Common Name matches domain

## Key Technical Decisions

### Why Alpine Linux?

- Small image size (~5MB base)
- Security-focused (fewer attack vectors)
- Fast build and deployment times
- Sufficient for production workloads

### Why Separate Containers?

- **Scalability**: Each service can scale independently
- **Maintainability**: Updates/changes isolated to one service
- **Security**: Service isolation limits breach impact
- **Best Practice**: Follows Docker philosophy (one process per container)

### Why Health Checks?

- Ensures services are fully ready before dependent services start
- Prevents WordPress from trying to connect to MariaDB before it's ready
- Prevents Nginx from proxying to WordPress before PHP-FPM is listening
- Improves reliability and reduces startup errors

### Why PHP-FPM Instead of Apache?

- **Performance**: PHP-FPM is faster and more memory-efficient
- **Separation**: Web server (Nginx) and PHP processor are decoupled
- **Scalability**: Can scale PHP-FPM separately from web server
- **Modern**: Industry standard for production PHP applications

### Why WP-CLI?

- Automated WordPress installation
- Programmatic configuration (no manual setup)
- Easier to script and reproduce
- Commonly used in production environments

## Project Requirements (42 School)

This project fulfills the following 42 Inception requirements:

✅ Each service runs in a dedicated container
✅ Containers built from Alpine Linux (penultimate stable version)
✅ Custom Dockerfiles (no ready-made images from Docker Hub)
✅ Nginx with TLSv1.2/1.3 only
✅ WordPress with PHP-FPM (no Nginx inside)
✅ MariaDB only (no Nginx inside)
✅ Volumes for WordPress database and files
✅ Docker network connecting containers
✅ Containers restart on crash
✅ Domain name configured (ekashirs.42.fr pointing to localhost)
✅ No passwords in Dockerfiles (using secrets)
✅ Environment variables in .env file

## Troubleshooting

### Common Issues

**Issue: "Cannot connect to the Docker daemon"**
- Solution: Start Docker service: `sudo systemctl start docker`

**Issue: "port is already allocated"**
- Solution: Another service is using port 443. Find and stop it:
  ```bash
  sudo lsof -i :443
  sudo systemctl stop apache2  # if Apache is running
  ```

**Issue: "No space left on device"**
- Solution: Clean up Docker: `docker system prune -a --volumes`

**Issue: WordPress shows database connection error**
- Check MariaDB is running: `docker ps`
- Verify credentials match between secrets and .env
- Restart containers: `make down && make`

**Issue: "Your connection is not private" in browser**
- Expected with self-signed certificates
- Click "Advanced" → "Proceed to ekashirs.42.fr (unsafe)"
- Or install certificate in browser trust store

## Performance Optimization

### PHP-FPM Tuning

Edit PHP-FPM configuration to adjust worker processes:
```ini
pm = dynamic
pm.max_children = 50
pm.start_servers = 5
pm.min_spare_servers = 5
pm.max_spare_servers = 35
```

### MariaDB Tuning

Adjust `my.cnf` for better performance:
```ini
innodb_buffer_pool_size = 256M
max_connections = 100
query_cache_size = 32M
```

### Nginx Caching

Add caching directives in `nginx.conf`:
```nginx
location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
}
```

## Future Enhancements

Possible improvements:
- Add Redis for WordPress object caching
- Implement automated backups
- Add monitoring (Prometheus/Grafana)
- Set up CI/CD pipeline
- Add Adminer for database management
- Implement FTP server for file uploads
- Add static website service
- Configure PHP-FPM in production mode
- Implement log rotation
- Add automated SSL certificate renewal (Let's Encrypt)

## Resources

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose File Reference](https://docs.docker.com/compose/compose-file/)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [WordPress Developer Resources](https://developer.wordpress.org/)
- [MariaDB Knowledge Base](https://mariadb.com/kb/en/)
- [WP-CLI Documentation](https://wp-cli.org/)
- [Alpine Linux Packages](https://pkgs.alpinelinux.org/)