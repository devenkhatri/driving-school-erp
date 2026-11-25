#!/usr/bin/env bash
set -euo pipefail

cd /var/www/html

# Ensure storage & cache directories exist and are writable
mkdir -p \
    storage/app/public \
    storage/app/private \
    storage/framework/cache/data \
    storage/framework/sessions \
    storage/framework/views \
    storage/logs \
    bootstrap/cache

chown -R www-data:www-data storage bootstrap/cache

# Ensure public storage symlink exists
if [ ! -L public/storage ]; then
    php artisan storage:link --no-interaction || true
fi

# Wait for MySQL when DB_CONNECTION is mysql/mariadb
if [ "${DB_CONNECTION:-mysql}" = "mysql" ] || [ "${DB_CONNECTION:-mysql}" = "mariadb" ]; then
    echo "Waiting for database at ${DB_HOST:-db}:${DB_PORT:-3306}..."
    for i in $(seq 1 30); do
        if php -r '
            try {
                new PDO(
                    sprintf("mysql:host=%s;port=%s;dbname=%s", getenv("DB_HOST") ?: "db", getenv("DB_PORT") ?: "3306", getenv("DB_DATABASE") ?: ""),
                    getenv("DB_USERNAME") ?: "root",
                    getenv("DB_PASSWORD") ?: "",
                    [PDO::ATTR_TIMEOUT => 2]
                );
                exit(0);
            } catch (Throwable $e) {
                exit(1);
            }
        ' 2>/dev/null; then
            echo "Database is ready."
            break
        fi
        sleep 2
    done
fi

# Run migrations automatically if requested
if [ "${RUN_MIGRATIONS:-false}" = "true" ]; then
    php artisan migrate --force --no-interaction
fi

# Optimize caches in production
if [ "${APP_ENV:-local}" = "production" ]; then
    php artisan config:cache --no-interaction
    php artisan route:cache --no-interaction
    php artisan view:cache --no-interaction
fi

exec "$@"
