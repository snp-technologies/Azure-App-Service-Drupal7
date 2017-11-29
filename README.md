# Azure-App-Service-Drupal7
A Docker solution for Drupal 7 on Azure Web App for Containers

## Overview

In September 2017 [Microsoft announced the general availability](https://azure.microsoft.com/en-us/blog/general-availability-of-app-service-on-linux-and-web-app-for-containers/) of Web App for Containers and Azure App Service on Linux.

While it is possible to run Drupal websites with Azure App Service on Linux, its built-in image for PHP is not an ideal environment for Drupal in production. At SNP we turned our attention to the Web App for Containers resource as a way to provide custom Docker images for our customers. Our priorities were to:

* Include Drupal code in the image, not referenced from the Web App /home mount.
* Set custom permissions on the document root.
* Add Drush (the Drupal CLI) 
* Add Memcached
* Add more PHP extensions commonly used by Drupal 7 sites
* Add additional PHP configuration settings recommended for Drupal 7

This repository is an example solution for Drupal 7. By itself, this solution does not install Drupal. *You need to bring your own code and database.* (More about this below.) 

This repository is intended to satisfy common Drupal 7 use cases. We expect that users of this solution will customize it to varying degrees to match their application requirements. For instance, we include many PHP extensions commonly required by Drupal 7, but you may need to add one or more (or remove ones that you do not need).

### What are the customizations for Drupal 7?

The origin of this repository is a Docker solution for an [Azure App Service on Linux, PHP 5.6 base image](https://github.com/Azure-App-Service/php/tree/master/5.6.21-apache).

Our initial, significant changes are seen in the commit [5a1ad87](https://github.com/snp-technologies/Azure-App-Service-Drupal7/commit/5a1ad87ed08831f8d95460deb739d066b4fe46c3).

### What about Drupal 8 (and 6)?

We specifically had Drupal 7 in mind for this solution. You can tweak it to support Drupal 8 (or 6). It is our intent to release a separate repository for Drupal 8 soon. Follow https://github.com/snp-technologies/ for updates.

## Bring your own code

In the Dockerfile, there is a placeholder for your code: "[REPLACE WITH YOUR GIT REPOSITORY CLONE URL]". Alternatively, you can use the Docker COPY command to copy code from your local disk into the image.

## Bring your own database

MySQL (or other Drupal compatible database) is not included in the Dockerfile. You can add this to the Dockerfile, or utilize an external database resource such as [Azure Database for MySQL](https://docs.microsoft.com/en-us/azure/mysql/). 


