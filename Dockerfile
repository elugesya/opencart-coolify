FROM php:7.4-apache

LABEL maintainer="OpenCart 3.x Coolify Deployment"

# Install system dependencies and PHP extensions
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libzip-dev \
    libonig-dev \
    libxml2-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    unzip \
    curl \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
        gd \
        mysqli \
        pdo_mysql \
        mbstring \
        xml \
        zip \
        curl \
        opcache \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Enable Apache modules
RUN a2enmod rewrite headers ssl

# Copy PHP configuration
COPY opencart.ini /usr/local/etc/php/conf.d/opencart.ini

# Set working directory
WORKDIR /var/www/html

# Download and extract OpenCart 3.0.3.9
RUN curl -L -o opencart.zip "https://github.com/opencart/opencart/releases/download/3.0.3.9/opencart-3.0.3.9.zip" \
    && unzip opencart.zip -d /tmp/opencart \
    && mv /tmp/opencart/upload/* /var/www/html/ \
    && rm -rf /tmp/opencart opencart.zip \
    && rm -f /var/www/html/config-dist.php /var/www/html/admin/config-dist.php \
    && rm -f /var/www/html/install.txt /var/www/html/license.txt

# Copy iyzico plugin into the image
COPY upload/ /var/www/html/

# Set proper permissions for OpenCart 3.x
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html \
    && chmod -R 775 /var/www/html/image/ \
    && chmod -R 775 /var/www/html/image/cache/ \
    && chmod -R 775 /var/www/html/image/catalog/ \
    && chmod -R 775 /var/www/html/system/storage/ \
    && chmod -R 775 /var/www/html/system/storage/cache/ \
    && chmod -R 775 /var/www/html/system/storage/download/ \
    && chmod -R 775 /var/www/html/system/storage/logs/ \
    && chmod -R 775 /var/www/html/system/storage/modification/ \
    && chmod -R 775 /var/www/html/system/storage/session/ \
    && chmod -R 775 /var/www/html/system/storage/upload/

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose port
EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]
CMD ["apache2-foreground"]
