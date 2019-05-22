FROM php:7.1-apache
MAINTAINER snp-technologies

ARG GIT_TOKEN
ARG BRANCH
ARG GIT_REPO

COPY apache2.conf /bin/
COPY init_container.sh /bin/

RUN a2enmod rewrite expires include deflate

###  Configure root user credentials ###
RUN chmod 755 /bin/init_container.sh \
    && echo "root:Docker!" | chpasswd \
    && echo "cd /home" >> /etc/bash.bashrc

# Install the PHP extensions we need
# From https://github.com/docker-library/drupal/blob/9c086fdeb757ae146d71384bdeb5103dd54b6d28/7/apache/Dockerfile
# With a few edits

RUN 	apt-get update; \
	apt-get install -y --no-install-recommends \
		libjpeg-dev \
		libpng-dev \
		libpq-dev \
                openssh-server \
                curl \
                git \
                mysql-client \
                nano \
                sudo \
                tcptraceroute \
                vim \
                wget \
                libssl-dev \
	; \
	\
	docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr; \
	docker-php-ext-install -j "$(nproc)" \
		gd \
                mbstring \
		opcache \
		pdo_mysql \
		zip \
	;

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
		echo 'opcache.memory_consumption=128'; \
		echo 'opcache.interned_strings_buffer=8'; \
		echo 'opcache.max_accelerated_files=4000'; \
		echo 'opcache.revalidate_freq=60'; \
		echo 'opcache.fast_shutdown=1'; \
		echo 'opcache.enable_cli=1'; \
       } > /usr/local/etc/php/conf.d/opcache-recommended.ini

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
   && rm -rf /var/www/html \
   && rm -rf /var/log/apache2 \
   && mkdir -p /home/LogFiles \
   && ln -s /home/LogFiles  /var/log/apache2

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
  echo 'upload_max_filesize = 8M'; \
  echo 'post_max_size = 8M'; \
  } > /usr/local/etc/php/conf.d/php.ini

# Installs memcached support for php
RUN apt-get update && apt-get install -y libmemcached-dev zlib1g-dev \
    && pecl install memcached-3.1.3 \
    && docker-php-ext-enable memcached
RUN apt-get update && apt-get install -y memcached

COPY sshd_config /etc/ssh/

EXPOSE 2222 8080

ENV APACHE_RUN_USER www-data
ENV PHP_VERSION 7.1

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
RUN git clone -b $BRANCH https://$GIT_TOKEN@github.com/$GIT_REPO.git .
# Add directories for public and private files
RUN mkdir -p  /home/site/wwwroot/sites/default/files \
    && mkdir -p  /home/site/wwwroot/sites/default/files/private \
    && ln -s /home/site/wwwroot/sites/default/files  /var/www/html/docroot/sites/default/files \
    && ln -s /home/site/wwwroot/sites/default/files/private  /var/www/html/docroot/sites/default/files/private

### Webroot permissions per www.drupal.org/node/244924#linux-servers ###
WORKDIR /var/www/html/docroot
RUN chown -R root:www-data .
RUN find . -type d -exec chmod u=rwx,g=rx,o= '{}' \;
RUN find . -type f -exec chmod u=rw,g=r,o= '{}' \;
# For sites/default/files directory, permissions come from
# /home/site/wwwroot/sites/default/files

ENTRYPOINT ["/bin/init_container.sh"]