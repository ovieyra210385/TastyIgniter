# Imagen base con Apache y PHP 8.2
FROM php:8.2-apache

# Instala extensiones necesarias
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg62-turbo-dev \
    libxml2-dev \
    libzip-dev \
    zlib1g-dev \
    zip \
    unzip \
    git \
    curl \
    && docker-php-ext-configure gd --with-jpeg \
    && docker-php-ext-install pdo_mysql mbstring zip exif pcntl gd

# Habilita mod_rewrite para Laravel/TastyIgniter
RUN a2enmod rewrite

# Corrige DocumentRoot para servir desde /public
RUN sed -i 's|DocumentRoot /var/www/html|DocumentRoot /var/www/html/public|g' /etc/apache2/sites-available/000-default.conf

# Instala Composer desde imagen oficial
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Copia el código fuente
COPY . /var/www/html

# Instala dependencias ignorando extensiones faltantes temporalmente
RUN composer install --no-dev --optimize-autoloader --ignore-platform-req=ext-*

# Establece permisos adecuados
RUN chown -R www-data:www-data /var/www/html \
    && find /var/www/html -type f -exec chmod 644 {} \; \
    && find /var/www/html -type d -exec chmod 755 {} \;

# Define el directorio de trabajo
WORKDIR /var/www/html

# Expone el puerto 80
EXPOSE 80

# Comando de inicio para Apache
CMD ["apache2-foreground"]
