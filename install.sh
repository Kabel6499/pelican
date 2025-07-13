#!/bin/bash

## Update Debian BAsed System

apt update
apt upgrade -y

echo The System is now Updated

## Install Apache2

apt install apache2 -y
## Install PHP 8.4 with all debendencies 

## Adding PHP Repo
sudo apt install software-properties-common -y
sudo add-apt-repository ppa:ondrej/php -y

## Install PHP 8.4
sudo apt install php8.4 php8.4-fpm -y

## Installing all PHP dependencies for Pelican Panel

sudo apt install php8.4-{gd,mysql,mbstring,bcmath,xml,curl,zip,intl,sqlite3,fpm} -y

## Instaling other dependencies for pelican

apt install curl
apt install tar
apt install unzip

## Installing Database Server

apt install mysql-server

## Creating Directory and Download Pelican Repo


sudo mkdir -p /var/www/pelican
cd /var/www/pelican

curl -L https://github.com/pelican-dev/panel/releases/latest/download/panel.tar.gz | sudo tar -xzv

## Installing Composer

curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer

sudo COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader

## Installing Certbot / SSL Certificates

sudo apt install -y python3-certbot-apache

certbot certonly --apache -d panel.kabel6499.de
certbot certonly --apache -d node.kabel6499.de

## Disable Default Site

a2dissite 000-default default-ssl 000-default-le-ssl

cd /etc/apache2/sites-available/pelican.conf
curl https://raw.githubusercontent.com/kabel6499/pelican/main/pelican.conf
cd /root/

sudo a2ensite pelican.conf
sudo a2enmod rewrite
sudo a2enmod php8.4

sudo systemctl restart apache2

php artisan p:environment:setup

sudo chmod -R 755 storage/* bootstrap/cache/

sudo chown -R www-data:www-data /var/www/pelican

## Installing Wings

curl -sSL https://get.docker.com/ | CHANNEL=stable sudo sh

curl -sSL https://get.docker.com/ | CHANNEL=stable sudo sh

sudo mkdir -p /etc/pelican /var/run/wings
sudo curl -L -o /usr/local/bin/wings "https://github.com/pelican-dev/wings/releases/latest/download/wings_linux_$([[ "$(uname -m)" == "x86_64" ]] && echo "amd64" || echo "arm64")"
sudo chmod u+x /usr/local/bin/wings

