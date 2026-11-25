# -----------------------------------------------------------------------------
# Stage 1: Build frontend assets with Node & Vite
# -----------------------------------------------------------------------------
FROM node:22-alpine AS assets

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci --no-audit --no-fund

COPY vite.config.js ./
COPY resources/ resources/
COPY public/ public/

RUN npm run build

# -----------------------------------------------------------------------------
# Stage 2: Install PHP Composer dependencies
# -----------------------------------------------------------------------------
FROM composer:2 AS vendor

WORKDIR /app

COPY composer.json composer.lock ./
RUN composer install \
    --no-dev \
    --no-interaction \
    --no-progress \
    --prefer-dist \
    --optimize-autoloader \
    --no-scripts

# -----------------------------------------------------------------------------
# Stage 3: PHP-FPM Application Runtime
# -----------------------------------------------------------------------------
FROM php:8.4-fpm-alpine AS app

WORKDIR /var/www/html

# Install system dependencies and PHP extensions required by Laravel 13 & MySQL
RUN apk add --no-cache \
    bash \
    curl \
    fcgi \
    freetype-dev \
    icu-dev \
    libjpeg-turbo-dev \
    libpng-dev \
    libwebp-dev \
    libzip-dev \
    mysql-client \
    oniguruma-dev \
    tzdata \
    && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install -j$(nproc) \
        bcmath \
        exif \
        gd \
        intl \
        mbstring \
        opcache \
        pcntl \
        pdo_mysql \
        zip \
    && rm -rf /var/cache/apk/*

# Copy PHP configuration
COPY docker/php/php.ini /usr/local/etc/php/conf.d/99-app.ini

# Copy application source
COPY . .

# Copy vendor and built frontend assets from build stages
COPY --from=vendor /app/vendor ./vendor
COPY --from=assets /app/public/build ./public/build

# Run Laravel package discovery after full source & vendor are present
RUN php artisan package:discover --ansi || true

# Copy entrypoint script
COPY docker/php/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Ensure writable directories exist and have proper ownership
RUN mkdir -p \
        storage/app/public \
        storage/app/private \
        storage/framework/cache/data \
        storage/framework/sessions \
        storage/framework/views \
        storage/logs \
        bootstrap/cache \
    && chown -R www-data:www-data storage bootstrap/cache

EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["php-fpm"]

# -----------------------------------------------------------------------------
# Stage 4: Nginx Web Server
# -----------------------------------------------------------------------------
FROM nginx:1.27-alpine AS web

WORKDIR /var/www/html

COPY docker/nginx/default.conf /etc/nginx/conf.d/default.conf
COPY --from=app /var/www/html/public ./public

EXPOSE 80
