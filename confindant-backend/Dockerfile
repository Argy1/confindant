FROM php:8.3-cli

WORKDIR /app

# System deps + PHP extensions
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libzip-dev \
    libssl-dev \
    libpq-dev \
    libgd-dev \
    pkg-config \
    ca-certificates \
    && docker-php-ext-install zip pdo pdo_pgsql pgsql gd \
    && rm -rf /var/lib/apt/lists/*

# Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Install PHP deps first for better layer caching
COPY composer.json composer.lock ./
RUN composer install --no-dev --optimize-autoloader --no-interaction --prefer-dist --no-scripts

# Copy app source
COPY . .

# Ensure writable storage/cache directories
RUN mkdir -p storage/framework/{cache,sessions,views} bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache

# Run Laravel package discovery after full source is present
RUN php artisan package:discover --ansi

EXPOSE 10000

CMD ["sh", "-c", "php artisan config:clear && php artisan route:clear && php artisan migrate --force && php artisan storage:link --quiet 2>/dev/null || true && php artisan serve --host=0.0.0.0 --port=${PORT:-10000}"]
