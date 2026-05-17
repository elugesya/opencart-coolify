#!/bin/bash
set -e

# OpenCart 3.x Coolify Deployment Entrypoint

OPENCART_DIR="/var/www/html"
CONFIG_FILE="${OPENCART_DIR}/config.php"
ADMIN_CONFIG_FILE="${OPENCART_DIR}/admin/config.php"

# Function to create OpenCart 3.x catalog config.php
create_catalog_config() {
    cat > "$CONFIG_FILE" <<EOF
<?php
// HTTP
define('HTTP_SERVER', '${APP_URL}/');

// HTTPS
define('HTTPS_SERVER', '${APP_URL}/');

// DIR
define('DIR_APPLICATION', '${OPENCART_DIR}/catalog/');
define('DIR_SYSTEM', '${OPENCART_DIR}/system/');
define('DIR_IMAGE', '${OPENCART_DIR}/image/');
define('DIR_STORAGE', '/var/www/storage/');
define('DIR_LANGUAGE', '${OPENCART_DIR}/catalog/language/');
define('DIR_TEMPLATE', '${OPENCART_DIR}/catalog/view/theme/');
define('DIR_CONFIG', '${OPENCART_DIR}/system/config/');
define('DIR_CACHE', DIR_STORAGE . 'cache/');
define('DIR_DOWNLOAD', DIR_STORAGE . 'download/');
define('DIR_LOGS', DIR_STORAGE . 'logs/');
define('DIR_MODIFICATION', DIR_STORAGE . 'modification/');
define('DIR_SESSION', DIR_STORAGE . 'session/');
define('DIR_UPLOAD', DIR_STORAGE . 'upload/');

// DB
define('DB_DRIVER', 'mysqli');
define('DB_HOSTNAME', '${DB_HOSTNAME}');
define('DB_USERNAME', '${DB_USERNAME}');
define('DB_PASSWORD', '${DB_PASSWORD}');
define('DB_DATABASE', '${DB_DATABASE}');
define('DB_PORT', '${DB_PORT}');
define('DB_PREFIX', '${DB_PREFIX}');
EOF
}

# Function to create OpenCart 3.x admin config.php
create_admin_config() {
    cat > "$ADMIN_CONFIG_FILE" <<EOF
<?php
// HTTP
define('HTTP_SERVER', '${APP_URL}/admin/');
define('HTTP_CATALOG', '${APP_URL}/');

// HTTPS
define('HTTPS_SERVER', '${APP_URL}/admin/');
define('HTTPS_CATALOG', '${APP_URL}/');

// DIR
define('DIR_APPLICATION', '${OPENCART_DIR}/admin/');
define('DIR_SYSTEM', '${OPENCART_DIR}/system/');
define('DIR_IMAGE', '${OPENCART_DIR}/image/');
define('DIR_STORAGE', '/var/www/storage/');
define('DIR_LANGUAGE', '${OPENCART_DIR}/admin/language/');
define('DIR_TEMPLATE', '${OPENCART_DIR}/admin/view/template/');
define('DIR_CONFIG', '${OPENCART_DIR}/system/config/');
define('DIR_CACHE', DIR_STORAGE . 'cache/');
define('DIR_DOWNLOAD', DIR_STORAGE . 'download/');
define('DIR_LOGS', DIR_STORAGE . 'logs/');
define('DIR_MODIFICATION', DIR_STORAGE . 'modification/');
define('DIR_SESSION', DIR_STORAGE . 'session/');
define('DIR_UPLOAD', DIR_STORAGE . 'upload/');

// DB
define('DB_DRIVER', 'mysqli');
define('DB_HOSTNAME', '${DB_HOSTNAME}');
define('DB_USERNAME', '${DB_USERNAME}');
define('DB_PASSWORD', '${DB_PASSWORD}');
define('DB_DATABASE', '${DB_DATABASE}');
define('DB_PORT', '${DB_PORT}');
define('DB_PREFIX', '${DB_PREFIX}');
EOF
}

# Ensure storage directory structure exists for OC 3.x
mkdir -p /var/www/storage/cache
mkdir -p /var/www/storage/logs
mkdir -p /var/www/storage/download
mkdir -p /var/www/storage/upload
mkdir -p /var/www/storage/modification
mkdir -p /var/www/storage/session
mkdir -p ${OPENCART_DIR}/image/cache
mkdir -p ${OPENCART_DIR}/image/catalog

# Set permissions
chown -R www-data:www-data ${OPENCART_DIR}
chown -R www-data:www-data /var/www/storage
chmod -R 755 ${OPENCART_DIR}
chmod -R 775 ${OPENCART_DIR}/image/
chmod -R 775 ${OPENCART_DIR}/image/cache/
chmod -R 775 ${OPENCART_DIR}/image/catalog/
chmod -R 775 /var/www/storage/

# Auto-create configs only if AUTO_CREATE_CONFIG is explicitly set to "true"
# Note: this requires the database to already have OpenCart tables,
# otherwise the storefront will crash. Use only when restoring/migrating.
if [ "${AUTO_CREATE_CONFIG}" = "true" ]; then
    if [ ! -f "$CONFIG_FILE" ] && [ -n "$DB_HOSTNAME" ] && [ -n "$DB_DATABASE" ]; then
        echo "AUTO_CREATE_CONFIG=true: Creating OpenCart config.php..."
        create_catalog_config
    fi

    if [ ! -f "$ADMIN_CONFIG_FILE" ] && [ -n "$DB_HOSTNAME" ] && [ -n "$DB_DATABASE" ]; then
        echo "AUTO_CREATE_CONFIG=true: Creating OpenCart admin/config.php..."
        create_admin_config
    fi
fi

# Show status
if [ -f "$CONFIG_FILE" ] && [ -f "$ADMIN_CONFIG_FILE" ]; then
    if [ -d "${OPENCART_DIR}/install" ]; then
        echo "========================================="
        echo "OpenCart config files present."
        echo "Install directory still exists."
        echo "If installation is complete, remove /install for security."
        echo "========================================="
    else
        echo "OpenCart 3.x is fully installed. Starting Apache..."
    fi
else
    echo "========================================="
    echo "OpenCart is ready for installation."
    echo "Please visit your site URL to run the web installer."
    echo ""
    echo "Database Settings for Installer:"
    echo "  Hostname: db"
    echo "  Username: ${DB_USERNAME}"
    echo "  Password: ${DB_PASSWORD}"
    echo "  Database: ${DB_DATABASE}"
    echo "  Port:     3306"
    echo "  Prefix:   ${DB_PREFIX}"
    echo "========================================="
fi

exec "$@"
