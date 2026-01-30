#!/bin/bash
set -e

# Read secrets
DB_PASSWORD=$(cat /run/secrets/db_password)
WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
WP_USER_PASSWORD=$(cat /run/secrets/wp_user_password)

# Set DB variables
DB_HOST=mariadb
DB_USER=$MYSQL_USER
DB_NAME=$MYSQL_DATABASE

# Configure msmtp to fail silently (just log, don't actually send)
cat > /etc/msmtprc <<EOF
defaults
logfile /var/log/msmtp/msmtp.log

account default
host 127.0.0.1
port 25
from noreply@${WP_DOMAIN}
auth off
tls off
timeout 5
EOF

chmod 644 /etc/msmtprc

# Configure PHP to use a wrapper script that won't fail
cat > /usr/local/bin/sendmail-wrapper.sh <<'EOF'
#!/bin/sh
# Try to send, but don't fail if it doesn't work
/usr/bin/msmtp -t "$@" 2>/dev/null || true
exit 0
EOF

chmod +x /usr/local/bin/sendmail-wrapper.sh

# Tell PHP to use the wrapper
sed -i 's|;sendmail_path =|sendmail_path = /usr/local/bin/sendmail-wrapper.sh -t|' /etc/php83/php.ini

# Wait for MariaDB
echo "Waiting for MariaDB..."
until mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" -e "SELECT 1;" &> /dev/null; do
  echo "MariaDB not ready yet, sleeping 2s..."
  sleep 2
done
echo "MariaDB is ready!"

# WordPress setup
if [ ! -f /var/www/html/wp-config.php ]; then
    rm -rf /var/www/html/*
    wp core download --allow-root

    wp config create --allow-root \
        --dbname=$DB_NAME \
        --dbuser=$DB_USER \
        --dbpass=$DB_PASSWORD \
        --dbhost=$DB_HOST:3306

    wp core install --allow-root \
        --url=https://$WP_DOMAIN \
        --title="Inception" \
        --admin_user=$WP_ADMIN \
        --admin_password=$WP_ADMIN_PASSWORD \
        --admin_email=$WP_ADMIN_EMAIL

    wp config set WP_HOME "https://$WP_DOMAIN" --allow-root
    wp config set WP_SITEURL "https://$WP_DOMAIN" --allow-root

    wp user create --allow-root \
        $WP_USER $WP_USER_EMAIL \
        --user_pass=$WP_USER_PASSWORD
fi

PHP_FPM_POOL=/etc/php83/php-fpm.d/www.conf

sed -i "s|^;*listen =.*|listen = 0.0.0.0:9000|" $PHP_FPM_POOL
sed -i "s|^;*listen.owner =.*|listen.owner = nobody|" $PHP_FPM_POOL
sed -i "s|^;*listen.group =.*|listen.group = nobody|" $PHP_FPM_POOL
sed -i "s|^;*listen.mode =.*|listen.mode = 0660|" $PHP_FPM_POOL

exec php-fpm83 -F