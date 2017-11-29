FROM php:5.6.21-apache
MAINTAINER snp-technologies

COPY apache2.conf /bin/
COPY init_container.sh /bin/

RUN a2enmod rewrite expires include deflate

### Install PHP extensions we need. Configure root user credentials ###
RUN apt update \
    && apt install -y --no-install-recommends \
         libpng12-dev \
         libjpeg-dev \
         libpq-dev \
         libmcrypt-dev \
         libldap2-dev \
         libldb-dev \
         libicu-dev \
         libgmp-dev \
         libmagickwand-dev \
         openssh-server \
		 curl \
		 git \
		 mysql-client \
		 nano \
		 sudo \
		 tcptraceroute \
		 vim \
		 wget \
    && chmod 755 /bin/init_container.sh \
    && echo "root:Docker!" | chpasswd \
    && echo "cd /home" >> /etc/bash.bashrc \
    && ln -s /usr/lib/x86_64-linux-gnu/libldap.so /usr/lib/libldap.so \
    && ln -s /usr/lib/x86_64-linux-gnu/liblber.so /usr/lib/liblber.so \
    && ln -s /usr/include/x86_64-linux-gnu/gmp.h /usr/include/gmp.h \
    && rm -rf /var/lib/apt/lists/* \
    && pecl install imagick-beta \
    && docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr \
    && docker-php-ext-install \
         bcmath \
         bz2 \
         calendar \
         exif \
         gd \
         gmp \
         intl \
         ldap \
         mbstring \
         mcrypt \
         mysqli \
         opcache \
         pcntl \
         pdo \
         pdo_mysql \
         pdo_pgsql \
         pgsql \
         phar \
         soap \
         sockets \
         xmlrpc \
         zip \
    && docker-php-ext-enable imagick

### Change apache logs directory ###
RUN   \
   rm -f /var/log/apache2/* \
   && rmdir /var/lock/apache2 \
   && rmdir /var/run/apache2 \
   && rmdir /var/log/apache2 \
   && chmod 777 /var/log \
   && chmod 777 /var/run \
   && chmod 777 /var/lock \
   && chmod 777 /bin/init_container.sh \
   && cp /bin/apache2.conf /etc/apache2/apache2.conf \
   && rm -rf /var/log/apache2 \
   && mkdir -p /home/LogFiles \
   && ln -s /home/LogFiles  /var/log/apache2

RUN { \
                echo 'opcache.memory_consumption=128'; \
                echo 'opcache.interned_strings_buffer=8'; \
                echo 'opcache.max_accelerated_files=4000'; \
                echo 'opcache.revalidate_freq=60'; \
                echo 'opcache.fast_shutdown=1'; \
                echo 'opcache.enable_cli=1'; \
    } > /usr/local/etc/php/conf.d/opcache-recommended.ini

# Include PHP recommendations from https://www.drupal.org/docs/7/system-requirements/php
RUN { \
  echo 'error_log=/var/log/apache2/php-error.log'; \
  echo 'log_errors=On'; \
  echo 'display_startup_errors=Off'; \
  echo 'date.timezone=UTC'; \
  echo 'session.cache_limiter = nocache'; \
  echo 'session.auto_start = 0'; \
  echo 'expose_php = off'; \
  echo 'allow_url_fopen = off'; \
  echo 'magic_quotes_gpc = off'; \  
  echo 'register_globals = off'; \  
  echo 'display_errors=Off'; \
  } > /usr/local/etc/php/conf.d/php.ini

COPY sshd_config /etc/ssh/

EXPOSE 2222 8080

ENV APACHE_RUN_USER www-data
ENV PHP_VERSION 5.6.21

ENV PORT 8080
ENV WEBSITE_ROLE_INSTANCE_ID localRoleInstance
ENV WEBSITE_INSTANCE_ID localInstance
ENV PATH ${PATH}:/var/www/html

### Begin Drush install ###

RUN wget https://github.com/drush-ops/drush/releases/download/8.1.13/drush.phar
RUN chmod +x drush.phar
RUN mv drush.phar /usr/local/bin/drush
RUN drush init -y

### END Drush install ###

WORKDIR /var/www/html/

### Git clone Drupal code with personal access token ###
RUN git clone -b master [REPLACE WITH YOUR GIT REPOSITORY CLONE URL] .
# Add directories for public and private files
RUN mkdir -p  /home/site/wwwroot/sites/default/files \
    && mkdir -p  /home/site/wwwroot/sites/default/files/private \
    && ln -s /home/site/wwwroot/sites/default/files  /var/www/html/docroot/sites/default/files \
    && ln -s /home/site/wwwroot/sites/default/files/private  /var/www/html/docroot/sites/default/files/private

### Begin Memcached install ###

RUN apt-get update && apt-get install -y memcached

# Port to expose (default: 11211)
EXPOSE 11211

# Default Memcached run command arguments
CMD ["-m", "64", memcached]

# Set the user to run Memcached daemon
USER root

# PHP extension
RUN \
cd /usr/src/php/ext \
&& pecl download memcache-3.0.8 \
&& gzip -d < memcache-3.0.8.tgz | tar -xvf - \
&& rm memcache-3.0.8.tgz \
&& mv memcache-3.0.8 memcache \
&& docker-php-ext-install memcache

# Update memcached.conf
RUN sed -i 's/-l 127.0.0.1/#/g' /etc/memcached.conf
RUN sed -i 's/memcache/root/g' /etc/memcached.conf

### End Memcached install ###

### Webroot permissions per www.drupal.org/node/244924#linux-servers ###
WORKDIR /var/www/html/docroot
RUN chown -R root:www-data .
RUN find . -type d -exec chmod u=rwx,g=rx,o= '{}' \;
RUN find . -type f -exec chmod u=rw,g=r,o= '{}' \;
# For sites/default/files directory, permissions come from
# /home/site/wwwroot/sites/default/files

#ENTRYPOINT service memcached start && /bin/bash
ENTRYPOINT ["/bin/init_container.sh"]