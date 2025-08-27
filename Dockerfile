# Base con Apache y PHP 8.3 (TastyIgniter 4.x requiere PHP 8.3+)
FROM php:8.3-apache

# Instala dependencias del sistema y extensiones PHP necesarias
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
    cron \
    && docker-php-ext-configure gd --with-jpeg \
    && docker-php-ext-install pdo_mysql mbstring zip exif pcntl gd bcmath tokenizer ctype dom \
    && rm -rf /var/lib/apt/lists/*

# Habilita mod_rewrite y headers
RUN a2enmod rewrite headers

# Corrige DocumentRoot para servir desde /public
RUN sed -i 's|DocumentRoot /var/www/html|DocumentRoot /var/www/html/public|g' /etc/apache2/sites-available/000-default.conf

# Copia Composer desde la imagen oficial
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Establece directorio de trabajo
WORKDIR /var/www/html

# Copia composer.json y composer.lock (si existe)
COPY composer.json ./
COPY composer.lock ./ || echo "No composer.lock found, se generará durante install"

# Instala dependencias PHP y asegura la generación de vendor/
RUN composer install --no-dev --optimize-autoloader --ignore-platform-req=ext-* --prefer-dist --no-scripts

# Copia todo el código fuente
COPY . .

# Copia el .htaccess optimizado en public/
COPY .htaccess ./public/.htaccess

# Ajusta permisos correctos para Apache
RUN chown -R www-data:www-data /var/www/html \
    && find /var/www/html -type f -exec chmod 644 {} \; \
    && find /var/www/html -type d -exec chmod 755 {} \;

# Ejecuta instalación de TastyIgniter en modo no interactivo
RUN php artisan igniter:install --no-interaction || echo "TastyIgniter ya instalado o requiere revisión manual"

# Configura cron para scheduler
RUN echo "* * * * * www-data php /var/www/html/artisan schedule:run >> /dev/null 2>&1" >> /etc/cron.d/tastyigniter \
    && chmod 0644 /etc/cron.d/tastyigniter \
    && crontab -u www-data /etc/cron.d/tastyigniter

# Expone el puerto 80
EXPOSE 80

# Comando de inicio
CMD ["apache2-foreground"]
