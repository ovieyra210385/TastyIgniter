FROM php:8.2-apache

# Instala extensiones necesarias
RUN apt-get update && apt-get install -y \
    libpng-dev libjpeg-dev libonig-dev libxml2-dev \
    zip unzip git curl libzip-dev \
    && docker-php-ext-install pdo_mysql mbstring zip exif pcntl

# Habilita mod_rewrite
RUN a2enmod rewrite

# Corrige DocumentRoot
RUN sed -i 's|DocumentRoot /var/www/html|DocumentRoot /var/www/html/public|g' /etc/apache2/sites-available/000-default.conf

# Instala Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Copia el código fuente
COPY . /var/www/html

# Instala dependencias
RUN composer install --no-dev --optimize-autoloader

# Establece permisos
RUN chown -R www-data:www-data /var/www/html \
    && find /var/www/html -type f -exec chmod 644 {} \; \
    && find /var/www/html -type d -exec chmod 755 {} \;

WORKDIR /var/www/html
EXPOSE 80
CMD ["apache2-foreground"]
