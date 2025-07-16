#!/bin/bash

export NEWT_COLORS='
root=,blue
window=,black
border=white,black
textbox=white,black
button=black,white
entry=,black
checkbox=,black
compactbutton=,black
'


IP=""
DOMAIN=""

error_handler() {
    local exit_code=$?
    local line_number=$1
    local last_command="${BASH_COMMAND}"
    local msg
    msg=$(printf "Error in Line %s:\n\n%s\n\nExit-Code: %s" "$line_number" "$last_command" "$exit_code")
    whiptail --title "Error" --msgbox "$msg\nIf you don't know how to fix the issue, report it on the repository." 15 70
    exit "$exit_code"
}

trap 'error_handler $LINENO' ERR
set -euo pipefail

get_ip_address() {
    ip_address=$(curl -s https://ipinfo.io/ip)
}

SystemUpdate() {
    apt update && apt upgrade -y
}

InstallApache() {
    apt install -y apache2
}

InstallPHP() {
    apt install -y software-properties-common
    add-apt-repository -y ppa:ondrej/php
    apt update
    apt install -y php8.4 php8.4-fpm php8.4-gd php8.4-mysql php8.4-mbstring \
        php8.4-bcmath php8.4-xml php8.4-curl php8.4-zip php8.4-intl php8.4-sqlite3 \
        libapache2-mod-php8.4
}

OtherDependencies() {
    apt install -y curl tar unzip
}

InstallMySQL() {
    echo "mysql-server mysql-server/root_password password $root_pw" | debconf-set-selections
    echo "mysql-server mysql-server/root_password_again password $root_pw" | debconf-set-selections
    apt install -y mysql-server

    mysql -u root -p"$root_pw" <<EOF
CREATE DATABASE IF NOT EXISTS $pelican_db;
CREATE USER IF NOT EXISTS '$panel_db_user'@'localhost' IDENTIFIED BY '$panel_pw';
GRANT ALL PRIVILEGES ON $pelican_db.* TO '$panel_db_user'@'localhost';
FLUSH PRIVILEGES;
EOF
}

panel_repo() {
    mkdir -p /var/www/pelican
    cd /var/www/pelican
    curl -L https://github.com/pelican-dev/panel/releases/latest/download/panel.tar.gz | tar -xzv
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
    COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader
}

install_certbot() {
    apt install -y python3-certbot-apache
}

panel_cert() {
    certbot --apache --non-interactive --agree-tos --redirect --email "$certbot_mail" -d "$panel_domain"
}

node_cert() {
    certbot --apache --non-interactive --agree-tos --redirect --email "$certbot_mail" -d "$node_domain"
}

apache_config() {
    a2dissite 000-default default-ssl 000-default-le-ssl 2>/dev/null || true

    if [ "$DOMAIN" = "YES" ]; then
        cat <<EOF > /etc/apache2/sites-available/pelican.conf
<VirtualHost *:80>
    ServerName $panel_domain
    RewriteEngine On
    RewriteCond %{HTTPS} !=on
    RewriteRule ^/?(.*) https://%{SERVER_NAME}/\$1 [R,L]
</VirtualHost>

<VirtualHost *:443>
    ServerName $panel_domain
    DocumentRoot "/var/www/pelican/public"

    AllowEncodedSlashes On
    php_value upload_max_filesize 100M
    php_value post_max_size 100M

    <Directory "/var/www/pelican/public">
        Require all granted
        AllowOverride all
    </Directory>

    SSLEngine on
    SSLCertificateFile /etc/letsencrypt/live/$panel_domain/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/$panel_domain/privkey.pem
</VirtualHost>
EOF
    elif [ "$IP" = "YES" ]; then
        cat <<EOF > /etc/apache2/sites-available/pelican.conf
<VirtualHost *:80>
    ServerName $panel_address
    DocumentRoot "/var/www/pelican/public"

    AllowEncodedSlashes On
    php_value upload_max_filesize 100M
    php_value post_max_size 100M

    <Directory "/var/www/pelican/public">
        Require all granted
        AllowOverride all
    </Directory>
</VirtualHost>
EOF
    fi
}

activate_apache() {
    a2ensite pelican.conf
    a2enmod ssl rewrite php8.4
    systemctl restart apache2
}

enable_panel() {
    systemctl restart apache2
    php artisan p:environment:setup
    chmod -R 755 storage/* bootstrap/cache/
    chown -R www-data:www-data /var/www/pelican
}

prompt_db_info() {
    root_pw=$(whiptail --title "Root DB Password" --passwordbox "Enter your Root SQL Password:" 10 60 3>&1 1>&2 2>&3)
    panel_pw=$(whiptail --title "Panel DB Password" --passwordbox "Enter your Panel SQL Password:" 10 60 3>&1 1>&2 2>&3)
    pelican_db=$(whiptail --title "DB Name" --inputbox "Database name for the panel?" 10 60 "panel" 3>&1 1>&2 2>&3)
    panel_db_user=$(whiptail --title "DB Username" --inputbox "Username for Panel DB?" 10 60 "pelican" 3>&1 1>&2 2>&3)
}

whip_http() {
    get_ip_address
    local http
    http=$(whiptail --title "Installation Type" --menu "Use Panel via IP or Domain?" 15 60 4 \
        "1" "IP" "2" "Domain" 3>&1 1>&2 2>&3)

    case "$http" in
        1) IP=YES; panel_address=$(whiptail --title "Server IP" --inputbox "Enter your IP address:" 10 60 "$ip_address" 3>&1 1>&2 2>&3) ;;
        2) DOMAIN=YES ;;
    esac
}

whip_panel() {
    if [ "$DOMAIN" = "YES" ]; then
        panel_domain=$(whiptail --title "Panel Domain" --inputbox "What is your Panel Domain?" 10 60 3>&1 1>&2 2>&3)
        certbot_mail=$(whiptail --title "Certbot Email" --inputbox "Enter your Email address:" 10 60 3>&1 1>&2 2>&3)
    fi
    prompt_db_info
    whiptail --title "Overview" --msgbox "Domain: $panel_domain\nDB: $pelican_db\nUser: $panel_db_user" 12 60
}

whip_node() {
    if [ "$DOMAIN" = "YES" ]; then
        node_domain=$(whiptail --title "Node Domain" --inputbox "Enter your Node Domain:" 10 60 3>&1 1>&2 2>&3)
        certbot_mail=$(whiptail --title "Certbot Email" --inputbox "Enter your Email address:" 10 60 3>&1 1>&2 2>&3)
    fi
}

wings_repo() {
    curl -sSL https://get.docker.com/ | CHANNEL=stable sh
    mkdir -p /etc/pelican /var/run/wings
    curl -L -o /usr/local/bin/wings "https://github.com/pelican-dev/wings/releases/latest/download/wings_linux_$([[ "$(uname -m)" == "x86_64" ]] && echo "amd64" || echo "arm64")"
    chmod +x /usr/local/bin/wings
}

systemcd_config() {
    cat <<EOF > /etc/systemd/system/wings.service
[Unit]
Description=Wings Daemon
After=docker.service
Requires=docker.service
PartOf=docker.service

[Service]
User=root
WorkingDirectory=/etc/pelican
LimitNOFILE=4096
PIDFile=/var/run/wings/daemon.pid
ExecStart=/usr/local/bin/wings
Restart=on-failure
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reexec
    systemctl enable wings
}

after_wings() {
    whiptail --title "Next Steps" --msgbox "Go back to the repository and follow the post-installation steps to finish setup." 12 60
}

# Start Menu
installation=$(whiptail --title "Installation Type" \
  --menu "What do you want to install?" 15 60 4 \
  "1" "Panel" \
  "2" "Wings" \
  "3" "Both" \
  3>&1 1>&2 2>&3)

case "$installation" in
  1)
    whip_http
    whip_panel
    SystemUpdate
    InstallApache
    InstallPHP
    OtherDependencies
    InstallMySQL
    panel_repo
    install_certbot
    apache_config
    activate_apache
    enable_panel
    ;;
  2)
    whip_node
    node_cert
    wings_repo
    systemcd_config
    after_wings
    ;;
  3)
    whip_http
    whip_panel
    whip_node
    SystemUpdate
    InstallApache
    InstallPHP
    OtherDependencies
    InstallMySQL
    panel_repo
    install_certbot
    apache_config
    activate_apache
    enable_panel
    node_cert
    wings_repo
    systemcd_config
    after_wings
    ;;
esac
