FROM alpine:3.22

RUN apk add --no-cache \
    php \
    php-fpm \
    php-cli \
    php-phar \
    php-mysqli \
    php-opcache \
    php-gd \
    php-curl \
    php-mbstring \
    php-session \
    php-tokenizer \
    php-ctype \
    mysql-client \
    bash \
    curl \
    unzip \
    msmtp

# PHP-FPM runtime dir
RUN mkdir -p /run/php

# Create msmtp log directory
RUN mkdir -p /var/log/msmtp && \
    chown nobody:nobody /var/log/msmtp

# Increase PHP CLI memory for WP-CLI
RUN echo "memory_limit=512M" > /etc/php83/conf.d/99-cli.ini

# Install WP-CLI
RUN curl -fsSL https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    -o /usr/local/bin/wp && chmod +x /usr/local/bin/wp

WORKDIR /var/www/html

COPY tools/setup.sh /setup.sh
RUN chmod +x /setup.sh

EXPOSE 9000
CMD ["/setup.sh"]