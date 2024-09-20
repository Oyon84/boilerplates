FROM php:8.2.23-zts-alpine3.20
WORKDIR /var/www/html

RUN apk update && \
    apk add icu-dev npm && \
    docker-php-ext-install intl && \
    curl -sS https://getcomposer.org/installer | php -- --version=2.7.9 --install-dir=/usr/local/bin --filename=composer && \
    mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

COPY . .

RUN composer install && npm install && \
    npm run build && php -ini | grep short_open_tag && \
    rm .env && mv .env.production .env

CMD ["php","artisan","serve","--host=0.0.0.0"]