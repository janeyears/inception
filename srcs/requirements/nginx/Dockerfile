FROM alpine:3.22

# Install packages
RUN apk add --no-cache nginx openssl bash

# Remove default site
RUN rm -f /etc/nginx/conf.d/default.conf

# Copy config
COPY conf/nginx.conf /etc/nginx/nginx.conf

EXPOSE 443

CMD ["nginx", "-g", "daemon off;"]
