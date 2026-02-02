# User Documentation

Welcome to the Inception project! This guide will help you set up and use a complete WordPress website with a secure HTTPS connection, powered by Docker containers.

## What Is This?

Inception is a self-hosted WordPress website infrastructure that runs on your machine using Docker. It includes:

- **Nginx**: Web server that handles HTTPS connections and serves your website
- **WordPress**: The popular content management system (CMS) for creating and managing your website
- **MariaDB**: Database that stores all your WordPress data (posts, pages, users, etc.)

All services run in isolated containers and communicate securely through a private network.

## Requirements

Before you start, make sure you have:

- **Docker**: Version 20.10 or higher ([Install Docker](https://docs.docker.com/get-docker/))
- **Docker Compose**: Version 1.29 or higher (usually included with Docker)
- **Make**: Build automation tool (pre-installed on most Linux systems)
- **At least 2GB RAM** available for the containers
- **1GB free disk space** for WordPress files and database

### Check if you have the requirements:

```bash
docker --version
docker-compose --version
make --version
```

## Quick Start Guide

### Step 1: Prepare Secrets

First, create password files for your services. These files keep your passwords secure.

```bash
# Create secrets directory
mkdir -p secrets/ssl

# Create password files (replace with your own strong passwords!)
echo "MyDatabasePassword123" > secrets/db_password.txt
echo "MyRootPassword456" > secrets/db_root_password.txt
echo "MyAdminPassword789" > secrets/wp_admin_password.txt
echo "MyUserPassword012" > secrets/wp_user_password.txt

# Secure the password files
chmod 600 secrets/*.txt
```

⚠️ **Important**: Use strong, unique passwords! Don't use the examples above.

### Step 2: Generate SSL Certificate

Create a self-signed SSL certificate for HTTPS:

```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout secrets/ssl/key.pem \
  -out secrets/ssl/cert.pem \
  -subj "/C=FR/ST=Paris/L=Paris/O=42/CN=ekashirs.42.fr"
```

This creates a certificate valid for 1 year.

### Step 3: Configure Environment Variables

Create a `.env` file in the `srcs/` directory:

```bash
# Create the file
touch srcs/.env
```

Edit `srcs/.env` and add your configuration:

```bash
# Domain name (must match SSL certificate CN)
WP_DOMAIN=ekashirs.42.fr

# WordPress admin user
WP_ADMIN=admin
WP_ADMIN_EMAIL=admin@example.com

# WordPress regular user
WP_USER=user
WP_USER_EMAIL=user@example.com

# Database configuration
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser
```

**Customize these values** for your setup!

### Step 4: Add Domain to Hosts File

Add your domain to `/etc/hosts` so your browser can find it:

```bash
echo "127.0.0.1 ekashirs.42.fr" | sudo tee -a /etc/hosts
```

⚠️ Change `ekashirs.42.fr` if you used a different domain in Step 3.

### Step 5: Build and Start

Build and start all services:

```bash
make
```

This will:
- Build Docker images for Nginx, WordPress, and MariaDB
- Create Docker volumes for persistent data
- Start all containers
- Set up WordPress automatically

**First launch takes 2-5 minutes.** You'll see logs from all three services.

### Step 6: Access Your WordPress Site

Once the build completes, open your browser and go to:

```
https://ekashirs.42.fr
```

**Note**: Your browser will show a security warning because we're using a self-signed certificate. This is normal and safe for local development.

- **Chrome/Edge**: Click "Advanced" → "Proceed to ekashirs.42.fr (unsafe)"
- **Firefox**: Click "Advanced" → "Accept the Risk and Continue"

You should see your WordPress homepage! 🎉

### Step 7: Log in to WordPress Admin

Access the WordPress admin panel:

```
https://ekashirs.42.fr/wp-admin
```

Log in with the credentials you set:
- **Username**: The value of `WP_ADMIN` from your `.env` file
- **Password**: The content of `secrets/wp_admin_password.txt`

## Managing Your Website

### Start the Services

If containers are stopped, start them again:

```bash
make
```

or

```bash
cd srcs
docker-compose up -d
```

### Stop the Services

Stop containers but keep all your data:

```bash
make down
```

Your WordPress content, database, and settings are preserved.

### Restart the Services

Restart all containers:

```bash
make down
make
```

### View Container Status

Check if all containers are running:

```bash
docker ps
```

You should see three containers: `nginx`, `wordpress`, and `mariadb` with "Up" status.

### View Logs

See what's happening in your containers:

```bash
# All services
docker-compose -f srcs/docker-compose.yml logs -f

# Specific service
docker logs nginx
docker logs wordpress  
docker logs mariadb
```

Press `Ctrl+C` to stop viewing logs.

### Full Cleanup

⚠️ **Warning**: This deletes everything including your WordPress posts and database!

```bash
make fclean
```

Use this if you want to start fresh or remove all Inception data.

### Rebuild Everything

Rebuild all images and restart with fresh data:

```bash
make re
```

This is equivalent to `make fclean` followed by `make`.

## Data Storage

Your WordPress data is stored in two locations:

```
/home/ekashirs/data/wordpress  - WordPress files, themes, plugins, uploads
/home/ekashirs/data/mariadb    - Database files
```

These directories are created automatically when you start the project.

### Backing Up Your Data

To backup your website:

```bash
# Create backup directory
mkdir -p ~/inception-backups

# Backup WordPress files
sudo tar -czf ~/inception-backups/wordpress-$(date +%Y%m%d).tar.gz \
  /home/ekashirs/data/wordpress

# Backup database files
sudo tar -czf ~/inception-backups/mariadb-$(date +%Y%m%d).tar.gz \
  /home/ekashirs/data/mariadb
```

### Restoring from Backup

To restore your data:

```bash
# Stop containers
make down

# Restore WordPress files
sudo tar -xzf ~/inception-backups/wordpress-YYYYMMDD.tar.gz -C /

# Restore database files
sudo tar -xzf ~/inception-backups/mariadb-YYYYMMDD.tar.gz -C /

# Start containers
make
```

## Troubleshooting

### Browser Shows "This site can't be reached"

**Problem**: Domain name not resolving.

**Solution**: 
1. Check if domain is in `/etc/hosts`:
   ```bash
   cat /etc/hosts | grep ekashirs.42.fr
   ```
2. If not there, add it:
   ```bash
   echo "127.0.0.1 ekashirs.42.fr" | sudo tee -a /etc/hosts
   ```

### Nginx Shows "502 Bad Gateway"

**Problem**: WordPress/PHP-FPM is not ready yet.

**Solution**:
1. Wait 30-60 seconds for WordPress to initialize
2. Check container status: `docker ps`
3. Check WordPress logs: `docker logs wordpress`
4. If still not working: `make down && make`

### "Database Connection Error" on WordPress

**Problem**: WordPress can't connect to MariaDB.

**Solution**:
1. Check MariaDB is running: `docker ps | grep mariadb`
2. Verify database passwords match in secrets files
3. Restart containers: `make down && make`

### "Port 443 already in use"

**Problem**: Another service is using port 443.

**Solution**:
1. Find what's using the port:
   ```bash
   sudo lsof -i :443
   ```
2. Stop the conflicting service:
   ```bash
   sudo systemctl stop apache2  # if Apache is running
   sudo systemctl stop nginx    # if system Nginx is running
   ```

### Forgot WordPress Admin Password

**Problem**: Can't log in to WordPress admin.

**Solution**:
1. Stop containers: `make down`
2. Change password in secrets file:
   ```bash
   echo "MyNewPassword" > secrets/wp_admin_password.txt
   chmod 600 secrets/wp_admin_password.txt
   ```
3. Rebuild WordPress container:
   ```bash
   cd srcs
   docker-compose build wordpress
   docker-compose up -d
   ```

### Containers Keep Restarting

**Problem**: Containers crash and restart continuously.

**Solution**:
1. Check logs for errors: `docker logs <container_name>`
2. Common causes:
   - Missing or incorrect secrets files
   - Wrong file permissions on secrets (should be 600)
   - Incorrect environment variables in `.env`
3. Verify all files exist:
   ```bash
   ls -la secrets/
   ls -la secrets/ssl/
   cat srcs/.env
   ```

### Running Out of Disk Space

**Problem**: "No space left on device" error.

**Solution**:
1. Clean up unused Docker resources:
   ```bash
   docker system prune -a --volumes
   ```
2. Warning: This removes all unused containers, images, and volumes!

## WordPress Management

### Installing Themes

1. Log in to WordPress admin: `https://ekashirs.42.fr/wp-admin`
2. Go to **Appearance** → **Themes**
3. Click **Add New**
4. Search for a theme, click **Install**, then **Activate**

### Installing Plugins

1. Go to **Plugins** → **Add New**
2. Search for a plugin
3. Click **Install Now**, then **Activate**

### Creating Posts and Pages

- **Posts**: Blog entries (Chronological content)
  - Go to **Posts** → **Add New**
- **Pages**: Static content (About, Contact, etc.)
  - Go to **Pages** → **Add New**

### Managing Users

Your site has two users by default:
1. **Admin user**: Full control (specified in `WP_ADMIN`)
2. **Regular user**: Limited permissions (specified in `WP_USER`)

To add more users:
1. Go to **Users** → **Add New**
2. Fill in details and choose a role (Administrator, Editor, Author, Contributor, Subscriber)

## Security Best Practices

### Use Strong Passwords

Always use strong passwords in your secrets files:
- At least 16 characters
- Mix of uppercase, lowercase, numbers, and symbols
- Different password for each service

### Keep WordPress Updated

Regularly update WordPress, themes, and plugins:
1. Log in to admin panel
2. Go to **Dashboard** → **Updates**
3. Click **Update Now** for each available update

### Regular Backups

Create backups before:
- Installing new plugins or themes
- Making major changes to your site
- Updating WordPress

See the "Backing Up Your Data" section above.

### Limit Admin Access

Don't share your admin credentials. Create separate accounts with appropriate permissions for other users.

## Performance Tips

### Monitor Resource Usage

Check Docker container resource usage:

```bash
docker stats
```

### Optimize WordPress

1. **Install a caching plugin**: WP Super Cache or W3 Total Cache
2. **Optimize images**: Use Smush or ShortPixel plugins
3. **Limit plugins**: Only install what you need
4. **Use a lightweight theme**: Avoid bloated themes with features you don't use

### Check Container Health

Verify all services are healthy:

```bash
docker ps
```

Look for "(healthy)" status next to each container.

## Advanced Usage

### Access Container Shell

Get a shell inside a container:

```bash
docker exec -it nginx sh
docker exec -it wordpress sh
docker exec -it mariadb sh
```

Type `exit` to leave the shell.

### Access MariaDB Directly

Connect to the database:

```bash
docker exec -it mariadb mysql -u root -p
```

Enter the root password from `secrets/db_root_password.txt`.

### Export/Import Database

**Export database:**

```bash
docker exec mariadb mysqldump -u root -p wordpress > backup.sql
```

**Import database:**

```bash
cat backup.sql | docker exec -i mariadb mysql -u root -p wordpress
```

### Using WP-CLI

WordPress CLI is available inside the WordPress container:

```bash
# List all posts
docker exec wordpress wp post list

# Create a new user
docker exec wordpress wp user create newuser user@example.com

# Update WordPress
docker exec wordpress wp core update
```

## Getting Help

### Check Service Status

```bash
# Container status
docker ps

# Detailed container info
docker inspect nginx
docker inspect wordpress
docker inspect mariadb
```

### View Full Logs

```bash
# Last 100 lines from all services
docker-compose -f srcs/docker-compose.yml logs --tail=100

# Follow logs in real-time
docker-compose -f srcs/docker-compose.yml logs -f

# Logs for specific service
docker logs nginx -f
```

### Test Network Connectivity

```bash
# Test if WordPress can reach MariaDB
docker exec wordpress nc -zv mariadb 3306

# Test if Nginx can reach WordPress
docker exec nginx nc -zv wordpress 9000
```

## Summary of Commands

| Action | Command |
|--------|---------|
| Start everything | `make` |
| Stop containers | `make down` |
| View container status | `docker ps` |
| View logs | `docker logs <container_name>` |
| Full cleanup | `make fclean` |
| Rebuild everything | `make re` |
| Access WordPress admin | `https://ekashirs.42.fr/wp-admin` |
| Access container shell | `docker exec -it <container> sh` |
| Check container health | `docker ps` |

---

**Need more technical details?** See [DEV_DOC.md](DEV_DOC.md) for developer documentation.

# User Documentation

Welcome to the Inception project! This guide will help you set up and use a complete WordPress website with a secure HTTPS connection, powered by Docker containers.

## What Is This?

Inception is a self-hosted WordPress website infrastructure that runs on your machine using Docker. It includes:

- **Nginx**: Web server that handles HTTPS connections and serves your website
- **WordPress**: The popular content management system (CMS) for creating and managing your website
- **MariaDB**: Database that stores all your WordPress data (posts, pages, users, etc.)

All services run in isolated containers and communicate securely through a private network.

## Requirements

Before you start, make sure you have:

- **Docker**: Version 20.10 or higher ([Install Docker](https://docs.docker.com/get-docker/))
- **Docker Compose**: Version 1.29 or higher (usually included with Docker)
- **Make**: Build automation tool (pre-installed on most Linux systems)
- **At least 2GB RAM** available for the containers
- **1GB free disk space** for WordPress files and database

### Check if you have the requirements:

```bash
docker --version
docker-compose --version
make --version
```

## Quick Start Guide

### Step 1: Prepare Secrets

First, create password files for your services. These files keep your passwords secure.

```bash
# Create secrets directory
mkdir -p secrets/ssl

# Create password files (replace with your own strong passwords!)
echo "MyDatabasePassword123" > secrets/db_password.txt
echo "MyRootPassword456" > secrets/db_root_password.txt
echo "MyAdminPassword789" > secrets/wp_admin_password.txt
echo "MyUserPassword012" > secrets/wp_user_password.txt

# Secure the password files
chmod 600 secrets/*.txt
```

⚠️ **Important**: Use strong, unique passwords! Don't use the examples above.

### Step 2: Generate SSL Certificate

Create a self-signed SSL certificate for HTTPS:

```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout secrets/ssl/key.pem \
  -out secrets/ssl/cert.pem \
  -subj "/C=FR/ST=Paris/L=Paris/O=42/CN=ekashirs.42.fr"
```

This creates a certificate valid for 1 year.

### Step 3: Configure Environment Variables

Create a `.env` file in the `srcs/` directory:

```bash
# Create the file
touch srcs/.env
```

Edit `srcs/.env` and add your configuration:

```bash
# Domain name (must match SSL certificate CN)
WP_DOMAIN=ekashirs.42.fr

# WordPress admin user
WP_ADMIN=admin
WP_ADMIN_EMAIL=admin@example.com

# WordPress regular user
WP_USER=user
WP_USER_EMAIL=user@example.com

# Database configuration
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser
```

**Customize these values** for your setup!

### Step 4: Add Domain to Hosts File

Add your domain to `/etc/hosts` so your browser can find it:

```bash
echo "127.0.0.1 ekashirs.42.fr" | sudo tee -a /etc/hosts
```

⚠️ Change `ekashirs.42.fr` if you used a different domain in Step 3.

### Step 5: Build and Start

Build and start all services:

```bash
make
```

This will:
- Build Docker images for Nginx, WordPress, and MariaDB
- Create Docker volumes for persistent data
- Start all containers
- Set up WordPress automatically

**First launch takes 2-5 minutes.** You'll see logs from all three services.

### Step 6: Access Your WordPress Site

Once the build completes, open your browser and go to:

```
https://ekashirs.42.fr
```

**Note**: Your browser will show a security warning because we're using a self-signed certificate. This is normal and safe for local development.

- **Chrome/Edge**: Click "Advanced" → "Proceed to ekashirs.42.fr (unsafe)"
- **Firefox**: Click "Advanced" → "Accept the Risk and Continue"

You should see your WordPress homepage! 🎉

### Step 7: Log in to WordPress Admin

Access the WordPress admin panel:

```
https://ekashirs.42.fr/wp-admin
```

Log in with the credentials you set:
- **Username**: The value of `WP_ADMIN` from your `.env` file
- **Password**: The content of `secrets/wp_admin_password.txt`

## Managing Your Website

### Start the Services

If containers are stopped, start them again:

```bash
make
```

or

```bash
cd srcs
docker-compose up -d
```

### Stop the Services

Stop containers but keep all your data:

```bash
make down
```

Your WordPress content, database, and settings are preserved.

### Restart the Services

Restart all containers:

```bash
make down
make
```

### View Container Status

Check if all containers are running:

```bash
docker ps
```

You should see three containers: `nginx`, `wordpress`, and `mariadb` with "Up" status.

### View Logs

See what's happening in your containers:

```bash
# All services
docker-compose -f srcs/docker-compose.yml logs -f

# Specific service
docker logs nginx
docker logs wordpress  
docker logs mariadb
```

Press `Ctrl+C` to stop viewing logs.

### Full Cleanup

⚠️ **Warning**: This deletes everything including your WordPress posts and database!

```bash
make fclean
```

Use this if you want to start fresh or remove all Inception data.

### Rebuild Everything

Rebuild all images and restart with fresh data:

```bash
make re
```

This is equivalent to `make fclean` followed by `make`.

## Data Storage

Your WordPress data is stored in two locations:

```
/home/ekashirs/data/wordpress  - WordPress files, themes, plugins, uploads
/home/ekashirs/data/mariadb    - Database files
```

These directories are created automatically when you start the project.

### Backing Up Your Data

To backup your website:

```bash
# Create backup directory
mkdir -p ~/inception-backups

# Backup WordPress files
sudo tar -czf ~/inception-backups/wordpress-$(date +%Y%m%d).tar.gz \
  /home/ekashirs/data/wordpress

# Backup database files
sudo tar -czf ~/inception-backups/mariadb-$(date +%Y%m%d).tar.gz \
  /home/ekashirs/data/mariadb
```

### Restoring from Backup

To restore your data:

```bash
# Stop containers
make down

# Restore WordPress files
sudo tar -xzf ~/inception-backups/wordpress-YYYYMMDD.tar.gz -C /

# Restore database files
sudo tar -xzf ~/inception-backups/mariadb-YYYYMMDD.tar.gz -C /

# Start containers
make
```

## Troubleshooting

### Browser Shows "This site can't be reached"

**Problem**: Domain name not resolving.

**Solution**: 
1. Check if domain is in `/etc/hosts`:
   ```bash
   cat /etc/hosts | grep ekashirs.42.fr
   ```
2. If not there, add it:
   ```bash
   echo "127.0.0.1 ekashirs.42.fr" | sudo tee -a /etc/hosts
   ```

### Nginx Shows "502 Bad Gateway"

**Problem**: WordPress/PHP-FPM is not ready yet.

**Solution**:
1. Wait 30-60 seconds for WordPress to initialize
2. Check container status: `docker ps`
3. Check WordPress logs: `docker logs wordpress`
4. If still not working: `make down && make`

### "Database Connection Error" on WordPress

**Problem**: WordPress can't connect to MariaDB.

**Solution**:
1. Check MariaDB is running: `docker ps | grep mariadb`
2. Verify database passwords match in secrets files
3. Restart containers: `make down && make`

### "Port 443 already in use"

**Problem**: Another service is using port 443.

**Solution**:
1. Find what's using the port:
   ```bash
   sudo lsof -i :443
   ```
2. Stop the conflicting service:
   ```bash
   sudo systemctl stop apache2  # if Apache is running
   sudo systemctl stop nginx    # if system Nginx is running
   ```

### Forgot WordPress Admin Password

**Problem**: Can't log in to WordPress admin.

**Solution**:
1. Stop containers: `make down`
2. Change password in secrets file:
   ```bash
   echo "MyNewPassword" > secrets/wp_admin_password.txt
   chmod 600 secrets/wp_admin_password.txt
   ```
3. Rebuild WordPress container:
   ```bash
   cd srcs
   docker-compose build wordpress
   docker-compose up -d
   ```

### Containers Keep Restarting

**Problem**: Containers crash and restart continuously.

**Solution**:
1. Check logs for errors: `docker logs <container_name>`
2. Common causes:
   - Missing or incorrect secrets files
   - Wrong file permissions on secrets (should be 600)
   - Incorrect environment variables in `.env`
3. Verify all files exist:
   ```bash
   ls -la secrets/
   ls -la secrets/ssl/
   cat srcs/.env
   ```

### Running Out of Disk Space

**Problem**: "No space left on device" error.

**Solution**:
1. Clean up unused Docker resources:
   ```bash
   docker system prune -a --volumes
   ```
2. Warning: This removes all unused containers, images, and volumes!

## WordPress Management

### Installing Themes

1. Log in to WordPress admin: `https://ekashirs.42.fr/wp-admin`
2. Go to **Appearance** → **Themes**
3. Click **Add New**
4. Search for a theme, click **Install**, then **Activate**

### Installing Plugins

1. Go to **Plugins** → **Add New**
2. Search for a plugin
3. Click **Install Now**, then **Activate**

### Creating Posts and Pages

- **Posts**: Blog entries (Chronological content)
  - Go to **Posts** → **Add New**
- **Pages**: Static content (About, Contact, etc.)
  - Go to **Pages** → **Add New**

### Managing Users

Your site has two users by default:
1. **Admin user**: Full control (specified in `WP_ADMIN`)
2. **Regular user**: Limited permissions (specified in `WP_USER`)

To add more users:
1. Go to **Users** → **Add New**
2. Fill in details and choose a role (Administrator, Editor, Author, Contributor, Subscriber)

## Security Best Practices

### Use Strong Passwords

Always use strong passwords in your secrets files:
- At least 16 characters
- Mix of uppercase, lowercase, numbers, and symbols
- Different password for each service

### Keep WordPress Updated

Regularly update WordPress, themes, and plugins:
1. Log in to admin panel
2. Go to **Dashboard** → **Updates**
3. Click **Update Now** for each available update

### Regular Backups

Create backups before:
- Installing new plugins or themes
- Making major changes to your site
- Updating WordPress

See the "Backing Up Your Data" section above.

### Limit Admin Access

Don't share your admin credentials. Create separate accounts with appropriate permissions for other users.

## Performance Tips

### Monitor Resource Usage

Check Docker container resource usage:

```bash
docker stats
```

### Optimize WordPress

1. **Install a caching plugin**: WP Super Cache or W3 Total Cache
2. **Optimize images**: Use Smush or ShortPixel plugins
3. **Limit plugins**: Only install what you need
4. **Use a lightweight theme**: Avoid bloated themes with features you don't use

### Check Container Health

Verify all services are healthy:

```bash
docker ps
```

Look for "(healthy)" status next to each container.

## Advanced Usage

### Access Container Shell

Get a shell inside a container:

```bash
docker exec -it nginx sh
docker exec -it wordpress sh
docker exec -it mariadb sh
```

Type `exit` to leave the shell.

### Access MariaDB Directly

Connect to the database:

```bash
docker exec -it mariadb mysql -u root -p
```

Enter the root password from `secrets/db_root_password.txt`.

### Export/Import Database

**Export database:**

```bash
docker exec mariadb mysqldump -u root -p wordpress > backup.sql
```

**Import database:**

```bash
cat backup.sql | docker exec -i mariadb mysql -u root -p wordpress
```

### Using WP-CLI

WordPress CLI is available inside the WordPress container:

```bash
# List all posts
docker exec wordpress wp post list

# Create a new user
docker exec wordpress wp user create newuser user@example.com

# Update WordPress
docker exec wordpress wp core update
```

## Getting Help

### Check Service Status

```bash
# Container status
docker ps

# Detailed container info
docker inspect nginx
docker inspect wordpress
docker inspect mariadb
```

### View Full Logs

```bash
# Last 100 lines from all services
docker-compose -f srcs/docker-compose.yml logs --tail=100

# Follow logs in real-time
docker-compose -f srcs/docker-compose.yml logs -f

# Logs for specific service
docker logs nginx -f
```

### Test Network Connectivity

```bash
# Test if WordPress can reach MariaDB
docker exec wordpress nc -zv mariadb 3306

# Test if Nginx can reach WordPress
docker exec nginx nc -zv wordpress 9000
```

## Frequently Asked Questions

**Q: Can I change the domain name?**

A: Yes! Update these:
1. `WP_DOMAIN` in `srcs/.env`
2. `/etc/hosts` entry
3. Regenerate SSL certificate with new domain
4. Rebuild: `make re`

**Q: Can I use a real domain name?**

A: Yes! Point your domain's DNS A record to your server's IP, update the configuration files, and use Let's Encrypt for a real SSL certificate.

**Q: How much resources does this use?**

A: Typical usage:
- CPU: 5-10% idle, 20-40% under load
- RAM: ~500MB total for all three containers
- Disk: ~500MB for system + your content size

**Q: Is this production-ready?**

A: This setup is designed for development and learning. For production:
- Use a proper SSL certificate (Let's Encrypt)
- Implement backups and monitoring
- Add Redis for caching
- Configure firewalls and security hardening
- Regular updates and maintenance

**Q: Can I add more services?**

A: Yes! You can extend `docker-compose.yml` to add services like:
- Redis (caching)
- Adminer (database GUI)
- FTP server
- Static website
- Email server

**Q: Where are the logs stored?**

A: Docker stores logs automatically. View them with `docker logs <container>`.

---

## Summary of Commands

| Action | Command |
|--------|---------|
| Start everything | `make` |
| Stop containers | `make down` |
| View container status | `docker ps` |
| View logs | `docker logs <container_name>` |
| Full cleanup | `make fclean` |
| Rebuild everything | `make re` |
| Access WordPress admin | `https://ekashirs.42.fr/wp-admin` |
| Access container shell | `docker exec -it <container> sh` |
| Check container health | `docker ps` |

---

**Need more technical details?** See [DEV_DOC.md](DEV_DOC.md) for developer documentation.
