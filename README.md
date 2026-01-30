*This project has been created as part of the 42 curriculum by ekashirs.*

# Inception

A complete WordPress infrastructure built with Docker from scratch.

[![42 Project](https://img.shields.io/badge/42-Project-blue)](https://42.fr)
[![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker)](https://www.docker.com/)
[![Alpine Linux](https://img.shields.io/badge/Alpine-3.22-0D597F?logo=alpine-linux)](https://alpinelinux.org/)

---

## 📋 Description

Inception is a system administration and DevOps project that builds a complete web infrastructure using **Docker** and **Docker Compose** from scratch.

The project deploys a fully functional WordPress website using:
- **Nginx** - HTTPS reverse proxy and web server (TLSv1.2/1.3)
- **WordPress** - PHP-FPM application server (no built-in web server)
- **MariaDB** - MySQL-compatible database server

### Key Features

✅ Each service runs in a dedicated container built from **Alpine Linux**  
✅ Custom Dockerfiles (no pre-made Docker Hub images)  
✅ TLS/SSL encryption (HTTPS only)  
✅ Docker secrets for sensitive credentials  
✅ Persistent volumes for data storage  
✅ Private Docker network for service isolation  
✅ Health checks and automatic restarts  
✅ Reproducible infrastructure as code  

---

## 📁 Project Structure

```
inception/
├── DEV_DOC.md                    # Developer documentation
├── USER_DOC.md                   # User guide
├── README.md                     # This file
├── Makefile                      # Build automation
├── secrets/                      # Applied by user (not in git)
│   ├── db_password.txt
│   ├── db_root_password.txt
│   ├── wp_admin_password.txt
│   ├── wp_user_password.txt
│   └── ssl/
│       ├── cert.pem
│       └── key.pem
└── srcs/
    ├── .env                      # Applied by user (not in git)
    ├── docker-compose.yml
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile
        │   ├── conf/
        │   │   └── my.cnf
        │   └── tools/
        │       └── init-db.sh
        ├── nginx/
        │   ├── Dockerfile
        │   └── conf/
        │       └── nginx.conf
        └── wordpress/
            ├── Dockerfile
            └── tools/
                └── setup.sh
```

---

## 🚀 Quick Start

### Prerequisites

- **Docker** (20.10+)
- **Docker Compose** (1.29+)
- **Make**
- **OpenSSL**

### Installation

**1. Clone the repository:**
```bash
git clone <repository-url>
cd inception
```

**2. Create secrets directory and password files:**
```bash
mkdir -p secrets/ssl
echo "your_strong_db_password" > secrets/db_password.txt
echo "your_strong_root_password" > secrets/db_root_password.txt
echo "your_strong_admin_password" > secrets/wp_admin_password.txt
echo "your_strong_user_password" > secrets/wp_user_password.txt
chmod 600 secrets/*.txt
```

**3. Generate SSL certificates:**
```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout secrets/ssl/key.pem \
  -out secrets/ssl/cert.pem \
  -subj "/C=FI/ST=Espoo/L=Espoo/O=42/CN=ekashirs.42.fr"
```

**4. Create and configure environment file:**
```bash
cat > srcs/.env << EOF
WP_DOMAIN=ekashirs.42.fr
WP_ADMIN=admin
WP_ADMIN_EMAIL=admin@example.com
WP_USER=user
WP_USER_EMAIL=user@example.com
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser
EOF
```

**5. Add domain to hosts file:**
```bash
echo "127.0.0.1 ekashirs.42.fr" | sudo tee -a /etc/hosts
```

**6. Build and start:**
```bash
make
```

**7. Access your WordPress site:**
```
https://ekashirs.42.fr
```

---

## 🛠️ Usage

| Command | Description |
|---------|-------------|
| `make` or `make all` | Build and start all services |
| `make down` | Stop containers (preserves data) |
| `make clean` | Stop and remove containers |
| `make fclean` | Full cleanup (removes volumes and data) |
| `make re` | Rebuild everything from scratch |

### View Logs

```bash
docker logs nginx
docker logs wordpress
docker logs mariadb
```

### Access WordPress Admin

```
URL: https://ekashirs.42.fr/wp-admin
Username: <WP_ADMIN from .env>
Password: <content of secrets/wp_admin_password.txt>
```

---

## 📚 Documentation

- **[USER_DOC.md](USER_DOC.md)** - Complete user guide with setup instructions, troubleshooting, and management
- **[DEV_DOC.md](DEV_DOC.md)** - Technical documentation for developers

---

## 🏗️ Architecture

### Service Communication

```
Client (HTTPS:443) → Nginx → WordPress (FastCGI:9000) → MariaDB (:3306)
```

### Container Details

| Service | Base Image | Exposed Port | Purpose |
|---------|-----------|--------------|---------|
| **nginx** | Alpine 3.22 | 443 (HTTPS) | Web server & reverse proxy |
| **wordpress** | Alpine 3.22 | 9000 (internal) | PHP-FPM application server |
| **mariadb** | Alpine 3.22 | 3306 (internal) | Database server |

### Data Persistence

- **WordPress files**: `/home/ekashirs/data/wordpress`
- **Database files**: `/home/ekashirs/data/mariadb`

---

## 🔐 Security Features

- **TLS/SSL encryption** - HTTPS only (no HTTP)
- **Docker secrets** - Sensitive data stored in files, not environment variables
- **Network isolation** - Private Docker network, only Nginx exposed
- **No default passwords** - All credentials user-defined
- **Minimal base images** - Alpine Linux for reduced attack surface

---

## 🎯 Design Choices

### Why Docker over Virtual Machines?

**Virtual Machines:**
- Run a full OS per service
- Heavy resource usage (GB of RAM per VM)
- Slow startup times

**Docker Containers:**
- Share host kernel
- Lightweight (MB of RAM)
- Fast startup and deployment
- Easy orchestration with Docker Compose

**Decision:** Docker for performance, portability, and simplicity.

### Why Docker Secrets over Environment Variables?

**Environment Variables:**
- Visible in `docker inspect`
- Exposed in container configuration
- Can leak in logs

**Docker Secrets:**
- Stored as files in `/run/secrets/`
- Not visible in container inspection
- Encrypted at rest (in Swarm mode)

**Decision:** Secrets for enhanced security.

### Why Private Docker Network?

**Host Networking:**
- Services exposed directly on host
- No isolation between containers
- Security risk

**Docker Bridge Network:**
- Services isolated from host
- Controlled inter-container communication
- Only Nginx port exposed

**Decision:** Private network for security and isolation.

### Why PHP-FPM (separate from web server)?

**Apache + mod_php (traditional):**
- Web server and PHP tightly coupled
- Harder to scale independently

**Nginx + PHP-FPM (modern):**
- Separation of concerns
- Better performance
- Independent scaling
- Industry standard

**Decision:** PHP-FPM for flexibility and performance.

---

## 📦 Technologies Used

- [Docker](https://www.docker.com/) - Container platform
- [Docker Compose](https://docs.docker.com/compose/) - Multi-container orchestration
- [Alpine Linux](https://alpinelinux.org/) - Lightweight base images
- [Nginx](https://nginx.org/) - High-performance web server
- [WordPress](https://wordpress.org/) - Content management system
- [PHP-FPM](https://www.php.net/manual/en/install.fpm.php) - FastCGI Process Manager
- [MariaDB](https://mariadb.org/) - MySQL-compatible database
- [WP-CLI](https://wp-cli.org/) - WordPress command-line interface
- [OpenSSL](https://www.openssl.org/) - SSL/TLS toolkit

---

## 🔧 Troubleshooting

### Common Issues

**"Cannot connect to Docker daemon"**
```bash
sudo systemctl start docker
```

**"Port 443 already in use"**
```bash
sudo lsof -i :443
sudo systemctl stop apache2  # or nginx
```

**"Database connection error"**
- Check MariaDB is running: `docker ps`
- Verify passwords match between secrets and .env
- Restart: `make down && make`

**Browser security warning**
- Normal with self-signed certificates
- Click "Advanced" → "Proceed" (safe for localhost)

For more troubleshooting, see [USER_DOC.md](USER_DOC.md#troubleshooting).

---

## 📝 Project Requirements (42 School)

This project fulfills all mandatory requirements:

✅ Docker Compose for multi-container setup  
✅ Custom Dockerfiles (no Docker Hub images)  
✅ Alpine Linux base (penultimate stable)  
✅ Nginx with TLSv1.2/1.3 only  
✅ WordPress + PHP-FPM (no Nginx)  
✅ MariaDB (no Nginx)  
✅ Two volumes (WordPress + MariaDB)  
✅ Docker network connecting containers  
✅ Containers restart on crash  
✅ Domain name pointing to localhost  
✅ No passwords in Dockerfiles  
✅ Environment variables via .env  

---

## 🤖 AI Usage

AI tools were used during this project for:
- Debugging container startup and networking issues
- Prototyping initialization scripts
- Optimizing Docker configurations
- Writing and structuring project documentation



