# https://github.com/jameskimmel/Nextcloud_Ubuntu/blob/main/nextcloud.md
FROM debian:12-slim
RUN apt update && \
    apt install -y \
    apache2 \
    bzip2 \
    cron \
    php \
    php8.2-ctype \
    php8.2-curl \
    php8.2-dom \
    php8.2-gd \
    php8.2-intl \
    php8.2-ldap \
    php8.2-mbstring \
    php8.2-memcached \
    php8.2-pgsql \
    php8.2-posix \
    php8.2-xml \
    php8.2-zip \
    sudo \
    wget

COPY ./files/latest.tar.bz2 /tmp/latest.tar.bz2
RUN cd tmp && \
    tar -xjvf latest.tar.bz2 && \
    mv nextcloud /var/www && \
    chown -R www-data:www-data /var/www/nextcloud && \
    rm latest.tar.bz2

RUN cd /var/www/nextcloud/apps && \
    wget -q -O- "https://github.com/nextcloud-releases/user_oidc/releases/download/v7.2.0/user_oidc-v7.2.0.tar.gz" | tar -xz
RUN chown www-data:www-data -R /var/www/nextcloud/apps

COPY ./files/apache2_nextcloud.conf /etc/apache2/sites-available/nextcloud.conf
COPY ./files/apache2.conf /etc/apache2/apache2.conf
COPY ./files/php.ini /etc/php/8.2/apache2/php.ini

RUN a2ensite nextcloud.conf && \
    a2dissite 000-default.conf && \
    a2enmod rewrite && \
    a2enmod headers && \
    a2enmod env && \
    a2enmod dir && \
    a2enmod mime

RUN sudo -u www-data mkdir /var/www/nextcloud/data

COPY ./files/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR "/var/www/nextcloud"
ENTRYPOINT "/entrypoint.sh"
