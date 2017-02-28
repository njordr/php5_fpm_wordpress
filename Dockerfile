FROM ubuntu:16.04

MAINTAINER "Giovanni Colapinto" alfheim@syshell.net

RUN apt-get update && apt-get install -y \
        build-essential \
        ca-certificates \
        curl \
        libedit2 \
        libsqlite3-0 \
        libxml2 \
        libedit-dev \
        libsqlite3-dev \
        libssl-dev \
        libxml2-dev \
        mysql-client \
        libsslcommon2-dev \
        libsasl2-dev \
        pkg-config \
        libcurl4-openssl-dev \
        libjpeg-dev \
        libpng12-dev \
        git \
        unzip \
        libmcrypt-dev \
    --no-install-recommends && rm -r /var/lib/apt/lists/*

ENV PHP_INI_DIR /usr/local/etc/php

RUN mkdir -p $PHP_INI_DIR/conf.d

ENV GPG_KEYS 0BD78B5F97500D450838F95DFE857D9A90D90EC1 6E4F6AB321FDC07F2C332E3AC2BF0BC433CFC8B3

ENV PHP_VERSION 5.6.25
ENV PHP_FILENAME php-5.6.25.tar.gz
ENV PHP_SHA256 7535cd6e20040ccec4594cc386c6f15c3f2c88f24163294a31068cf7dfe7f644

COPY src/php.tar.gz /usr/src/php.tar.gz

RUN cd /usr/src \
    && mkdir php \
    && tar xfz php.tar.gz -C php --strip-components 1 \
    && cd /usr/src/php \
    && ./configure \
        --with-config-file-path="$PHP_INI_DIR" \
        --with-config-file-scan-dir="$PHP_INI_DIR/conf.d" \
        \
        --disable-cgi \
        \
        --enable-ftp \
        --enable-mbstring \
        --with-mcrypt \
        --enable-mysqlnd \
        --with-mysql \
        --with-mysqli \
         --with-pdo-mysql \
        --with-gd \
        \
        --with-curl \
        --with-libedit \
        --with-openssl \
        --with-zlib \
        --enable-fpm \
        --with-fpm-user=www-data \
        --with-fpm-group=www-data \
    && make  \
    && make install \
    && cp -f php.ini-production $PHP_INI_DIR/php.ini \
    && { find /usr/local/bin /usr/local/sbin -type f -executable -exec strip --strip-all '{}' + || true; } \
    && make clean \
    && cd .. \
    && rm -Rf php

RUN cd /tmp \
    && curl -sS https://getcomposer.org/installer | php \
    && mv composer.phar /usr/local/bin/composer

WORKDIR /var/www/html

RUN set -ex \
    && cd /usr/local/etc \
    && if [ -d php-fpm.d ]; then \
        # for some reason, upstream's php-fpm.conf.default has "include=NONE/etc/php-fpm.d/*.conf"
        sed 's!=NONE/!=!g' php-fpm.conf.default | tee php-fpm.conf > /dev/null; \
        cp php-fpm.d/www.conf.default php-fpm.d/www.conf; \
    else \
        # PHP 5.x don't use "include=" by default, so we'll create our own simple config that mimics PHP 7+ for consistency
        mkdir php-fpm.d; \
        cp php-fpm.conf.default php-fpm.d/www.conf; \
        { \
            echo '[global]'; \
            echo 'include=etc/php-fpm.d/*.conf'; \
        } | tee php-fpm.conf; \
    fi \
    && { \
        echo '[global]'; \
        echo 'error_log = /proc/self/fd/2'; \
        echo; \
        echo '[www]'; \
        echo '; if we send this to /proc/self/fd/1, it never appears'; \
        echo 'access.log = /proc/self/fd/2'; \
        echo; \
        echo 'clear_env = no'; \
        echo; \
        echo '; Ensure worker stdout and stderr are sent to the main error log.'; \
        echo 'catch_workers_output = yes'; \
    } | tee php-fpm.d/docker.conf \
    && { \
        echo '[global]'; \
        echo 'daemonize = no'; \
        echo; \
        echo '[www]'; \
        echo 'listen = [::]:9000'; \
    } | tee php-fpm.d/zz-docker.conf

RUN curl -sL https://deb.nodesource.com/setup_6.x -o nodesource_setup.sh \
    && bash nodesource_setup.sh \
    && apt-get update && apt-get install -y \
        nodejs \
        --no-install-recommends && rm -r /var/lib/apt/lists/*

EXPOSE 9000
CMD ["php-fpm"]

