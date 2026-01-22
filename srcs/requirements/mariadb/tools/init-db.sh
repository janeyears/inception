#!/bin/bash
set -e

MYSQL_DATA_DIR=/var/lib/mysql

MYSQL_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
MYSQL_PASSWORD=$(cat /run/secrets/db_password)

# Create runtime dir
mkdir -p /run/mysqld

# Ensure permissions
chown -R mysql:mysql /run/mysqld /var/lib/mysql

# Init DB only if empty
if [ ! -d "$MYSQL_DATA_DIR/mysql" ]; then
    echo "Initializing MariaDB system tables..."
    mariadb-install-db --user=mysql --datadir="$MYSQL_DATA_DIR" --skip-test-db

    echo "Starting temporary MariaDB..."
    mariadbd --user=mysql --datadir="$MYSQL_DATA_DIR" --skip-networking --socket=/run/mysqld/mysqld.sock &
    pid="$!"

    echo "Waiting for MariaDB to start..."
    until mariadb --protocol=socket -u root -e "SELECT 1;" &>/dev/null; do
        sleep 1
    done

    echo "Configuring database..."
    mariadb --protocol=socket -u root <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF

    echo "Stopping temporary MariaDB..."
    mariadb-admin --protocol=socket -u root -p"${MYSQL_ROOT_PASSWORD}" shutdown

fi

echo "Starting MariaDB in foreground..."
exec mariadbd --user=mysql --datadir="$MYSQL_DATA_DIR"