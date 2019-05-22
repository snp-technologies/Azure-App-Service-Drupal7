# Azure-App-Service-Drupal7
A Docker solution for Drupal 7 on Azure Web App for Containers.

* [Overview](#overview)
* [Bring your own code](#byo-code)
* [Bring your own database](#byo-database)
* [Persistent Files](#files)
* [References](#references)

<a id="overview"></a>
## Overview

In September 2017 [Microsoft announced the general availability](https://azure.microsoft.com/en-us/blog/general-availability-of-app-service-on-linux-and-web-app-for-containers/) of Azure Web App for Containers and Azure App Service on Linux.

While it is possible to host Drupal websites with Azure App Service on Linux, its built-in image for PHP is not an ideal environment for Drupal in production. At SNP we turned our attention to the Web App for Containers resource as a way to provide custom Docker images for our customers. Our priorities were to:

* Include Drupal code in the image, not referenced from the Web App /home mount.
* Set custom permissions on the document root.
* Add Drush (the Drupal CLI) 
* Add Memcached support in PHP
* Add other PHP extensions commonly used by Drupal 7 sites
* Add additional PHP configuration settings recommended for Drupal 7

This repository is an example solution for Drupal 7. By itself, this solution does not install Drupal. *You need to bring your own code and database.* (More about this below.)

This repository is intended to satisfy common Drupal 7 use cases. We expect that users of this solution will customize it to varying degrees to match their application requirements. For instance, we include many PHP extensions commonly required by Drupal 7, but you may need to add one or more (or remove ones that you do not need).

### History of this repository

The origin of this repository in 2017 was  a Docker solution for an [Azure App Service on Linux, PHP 5.6 base image](https://github.com/Azure-App-Service/php/tree/master/5.6.21-apache).

Our initial, significant changes are seen in the commit [5a1ad87](https://github.com/snp-technologies/Azure-App-Service-Drupal7/commit/5a1ad87ed08831f8d95460deb739d066b4fe46c3).

In May 2019, we updated the repo to support PHP 7.1. Inspiration was taken from:

- [Official Docker container solution for Drupal](https://github.com/docker-library/drupal/blob/9c086fdeb757ae146d71384bdeb5103dd54b6d28/7/apache/Dockerfile)
- [Built in PHP 7.1 image for App Service on Linux](https://github.com/Azure/app-service-builtin-images/blob/master/php/7.2.1-apache/Dockerfile)

### What about Drupal 8 (and 6)?

We specifically had Drupal 7 in mind for this solution. You can tweak it to support Drupal 8 (or 6). Or, look at our [separate repository for Drupal 8](https://github.com/snp-technologies/Azure-App-Service-Drupal8).

<a id="byo-code"></a>
## Bring your own code

In the Dockerfile, there is a placeholder for your code: 
```
RUN git clone -b $BRANCH https://$GIT_TOKEN@github.com/$GIT_REPO.git .
```
Note the use of build args for `$BRANCH`, `$GIT_TOKEN`, and `$GIT_REPO`.

Alternatively, you can use the Docker COPY command to copy code from your local disk into the image.

Our recommendation is to place your code in a directory directly off the root of the repository. In this repository we provide a ```/docroot``` directory into which you can place your application code. In the Dockerfile, it is assumed that the application code is in the ```/docroot``` directory. Feel free, of course, to rename the directory with your preferred naming convention.

<a id="byo-database"></a>
## Bring your own database

MySQL (or other Drupal compatible database) is not included in the Dockerfile. You can add this to the Dockerfile, or utilize an external database resource such as [Azure Database for MySQL](https://docs.microsoft.com/en-us/azure/mysql/).

## Bring your own memcached

When we first posted this Docker solution for Drupal 7, we included a memcached installation in the `Dockerfile`. For the 7.1 update, we removed memcached. It is a better practice to connect to memcached running in a separate container. If you would like to include memcached in this solution, you can copy the necessary commands from the php5.6 branch into your fork.

### Connection string tip

The Azure Web App provides a setting into which you can enter a database connection string. This string is an environment variable within the Web App. At run-time, this environment variable can be interpreted in your `settings.php` file and parsed to populate your $databases array. However, in a container SSH session, the environment variable is not available. As a result Drush commands that require a database bootstrap level do not work.

An alternative to the Web App Connection string environment variable is to reference in `settings.php` a secrets file mounted to the Web App /home directory. For example, assume that we have a `secrets.txt` file that contains the string:
```
db=[mydb]&dbuser=[mydbuser]@[myazurewebappname]&dbpw=[mydbpassword]&dbhost=[mydb]
```
In our settings.php file, we can use the following code to populate the $databases array:
```
$secret = file_get_contents('/home/secrets.txt');
$secret = trim($secret);
$dbconnstring = parse_str($secret);
$databases = array (
  'default' => 
  array (
    'default' => 
    array (
      'database' => $db,
      'username' => $dbuser,
      'password' => $dbpw,
      'host' => $dbhost,
      'port' => '3306',
      'driver' => 'mysql',
      'prefix' => false,
    ),
  ),
);
```
<a id="files"></a>
## Persistent Files

In order to persist files, we leverage the Web App's `/home` directory that is mounted to Azure File Storage (see NOTE below). The `/home` directory is accessible from the container. As such, we persist files by making directories for `/files` and `/files/private` and then setting symbolic links, as follows:
```
# Add directories for public and private files
RUN mkdir -p  /home/site/wwwroot/sites/default/files \
    && mkdir -p  /home/site/wwwroot/sites/default/files/private \
    && ln -s /home/site/wwwroot/sites/default/files  /var/www/html/docroot/sites/default/files \
    && ln -s /home/site/wwwroot/sites/default/files/private  /var/www/html/docroot/sites/default/files/private
```
NOTE: By default, the Web App for Containers platform mounts an SMB share to the `/home` directory. You can do that by setting the `WEBSITES_ENABLE_APP_SERVICE_STORAGE` app setting to true or by removing the app setting entirely.

If the `WEBSITES_ENABLE_APP_SERVICE_STORAGE` setting is `false`, the `/home` directory will not be shared across scale instances, and files that are written there will not be persisted across restarts.

<a id="references"></a>
## References

* [Docker Hub Official Repository for php](https://hub.docker.com/r/_/php/)
* [Web App for Containers home page](https://azure.microsoft.com/en-us/services/app-service/containers/)
* [Use a custom Docker image for Web App for Containers](https://docs.microsoft.com/en-us/azure/app-service/containers/tutorial-custom-docker-image)
* [Understanding the Azure App Service file system](https://github.com/projectkudu/kudu/wiki/Understanding-the-Azure-App-Service-file-system)
* [Azure App Service on Linux FAQ](https://docs.microsoft.com/en-us/azure/app-service/containers/app-service-linux-faq)

Git repository sponsored by [SNP Technologies](https://www.snp.com)

If you are interested in a WordPress container solution, please visit https://github.com/snp-technologies/Azure-App-Service-WordPress.