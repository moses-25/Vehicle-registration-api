#!/bin/sh
set -e

if [ ! -f .env ]; then
    cp .env.example .env
fi

php artisan key:generate --force --ansi || true

chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache

echo "Waiting for database..."
until php -r "new PDO('pgsql:host=${DB_HOST};port=${DB_PORT};dbname=${DB_DATABASE}', '${DB_USERNAME}', '${DB_PASSWORD}');" > /dev/null 2>&1; do
    sleep 1
done
echo "Database is up."

php artisan migrate --force
php artisan db:seed --force || true

exec php-fpm