FROM alpine:3.22

RUN apk add --no-cache mariadb mariadb-client bash

# Create dirs and fix permissions
RUN mkdir -p /run/mysqld /var/lib/mysql \
    && chown -R mysql:mysql /run/mysqld /var/lib/mysql

COPY conf/my.cnf /etc/my.cnf

COPY tools/init-db.sh /init-db.sh
RUN chmod +x /init-db.sh

EXPOSE 3306
CMD ["/init-db.sh"]