# Imagen base con Apache y PHP 8.2
FROM php:8.2-apache

# Instala dependencias del sistema necesarias para PHP y Composer
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
    && docker-php-ext-install pdo_mysql mbstring zip exif pcntl gd \
    && rm -rf /var/lib/apt/lists/*

# Habilita mod_rewrite para Laravel/TastyIgniter
RUN a2enmod rewrite

# Corrige DocumentRoot para servir desde /public
RUN sed -i 's|DocumentRoot /var/www/html|DocumentRoot /var/www/html/public|g' /etc/apache2/sites-available/000-default.conf

# Instala Composer desde la imagen oficial
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Establece el directorio de trabajo
WORKDIR /var/www/html

# Copia solo composer.json
COPY composer.json ./

# Instala dependencias PHP y genera composer.lock si no existe
RUN composer install --no-dev --optimize-autoloader --ignore-platform-req=ext-*

# Copia el resto del código fuente
COPY . .

# Ajusta permisos para Apache
RUN chown -R www-data:www-data /var/www/html \
    && find /var/www/html -type f -exec chmod 644 {} \; \
    && find /var/www/html -type d -exec chmod 755 {} \;

# Expone el puerto 80
EXPOSE 80

# Comando de inicio
CMD ["apache2-foreground"]
