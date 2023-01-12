#!/bin/bash

# Script to automate security and deployment of a docker-compose file

# update the system
apt-get update
apt-get upgrade -y

# Stop and remove all containers
docker-compose down

# Build and run containers
docker-compose build
docker-compose up -d

# Generate random password for MySQL root user
MYSQL_ROOT_PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
echo "MySQL root password: $MYSQL_ROOT_PASSWORD"

# Update environment variables
echo "MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD" >> .env

# Update MySQL root user password
docker-compose exec mariadb mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';"

# Update file permissions
chmod 600 .env
chmod 600 docker-compose.yml

# Install necessary PHP dependencies
docker-compose exec php apt-get update -y
docker-compose exec php apt-get install -y \
    libfreetype6-dev \
    libjpeg-dev \
    libpng-dev \
    libmcrypt-dev \
    libicu-dev \
    libxml2-dev \
    libxslt-dev \
    libzip-dev \
    libonig-dev \
    zip \
    unzip

# Configure and install PHP extensions
docker-compose exec php docker-php-ext-configure gd --with-freetype --with-jpeg
docker-compose exec php docker-php-ext-install \
    -j$(nproc) \
    intl \
    gd \
    mysqli \
    pdo_mysql \
    opcache \
    xsl \
    soap \
    zip

# download wp-cli
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
mv wp-cli.phar /usr/local/bin/wp

# download and configure wordpress
wp core download
wp config create --dbname=example_db --dbuser=example_user --dbpass=example_password

# configure file permissions
chown -R www-data:www-data /var/www/html
find /var/www/html -type d -exec chmod 755 {} \;
find /var/www/html -type f -exec chmod 644 {} \;

# Update WordPress permissions to allow theme and plugin uploads
wp theme install --allow-root
wp plugin install --allow-root
docker-compose exec wordpress chown -R www-data:www-data /var/www/html/wp-content

