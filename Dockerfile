# 1. Imagen base oficial de PHP con Apache
FROM php:8.2-apache

# 2. Instalación de extensiones PDO para MySQL (Crucial para que save_asset.php funcione)
RUN docker-php-ext-install pdo pdo_mysql

# 3. Habilitar mod_rewrite de Apache para manejo de rutas
RUN a2enmod rewrite

# 4. Configurar el directorio de trabajo
WORKDIR /var/www/html

# 5. Ajuste de permisos para que el servidor pueda escribir y leer
RUN chown -R www-data:www-data /var/www/html

# Nota del Escéptico: Esta imagen no contiene el código, 
# el código lo inyectaremos vía volúmenes en el siguiente paso.