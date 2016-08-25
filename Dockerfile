FROM php:5.6.25-fpm

MAINTAINER "Giovanni Colapinto" alfheim@syshell.net

RUN apt-get update && apt-get install -y \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libpng12-dev \
        mysql-client \
        mysql-common \
    && docker-php-ext-install -j$(nproc) iconv mcrypt mysql mysqli \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd
