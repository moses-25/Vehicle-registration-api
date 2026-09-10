FROM php:8.4-fpm-alpine

RUN apk add --no-cache \
        postgresql-dev \
        libzip-dev \
        zip \
        unzip \
        git \
        oniguruma-dev \
    && docker-php-ext-install pdo pdo_pgsql pgsql bcmath mbstring zip

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www

COPY . .

RUN if [ -f composer.json ]; then composer install --no-interaction --optimize-autoloader --no-dev; fi \
    && chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache \
    && chmod +x docker/php/entrypoint.sh

EXPOSE 9000

ENTRYPOINT ["docker/php/entrypoint.sh"]