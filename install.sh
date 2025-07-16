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


SystemUpdate(){ 
    apt update
    apt upgrade -y
}

InstallApache(){
    apt install apache2 -y
}

InstallPHP(){
    apt install software-properties-common -y
    add-apt-repository ppa:ondrej/php -y
    apt install -y php8.4 php8.4-fpm php8.4-gd php8.4-mysql php8.4-mbstring php8.4-bcmath php8.4-xml php8.4-curl php8.4-zip php8.4-intl php8.4-sqlite3 libapache2-mod-php8.4
}

OtherDependencies(){
    apt install curl -y
    apt install tar -y
    apt install unzip -y
}

MySQL(){

        ## Installing Database Server
    echo "mysql-server mysql-server/root_password password $root_pw" | sudo debconf-set-selections
    echo "mysql-server mysql-server/root_password_again password $root_pw" | sudo debconf-set-selections

    apt install mysql-server -y

mysql -u root -p"$root_pw" <<EOF
CREATE DATABASE IF NOT EXISTS $pelican_db;
CREATE USER IF NOT EXISTS '$panel_db_user'@'localhost' IDENTIFIED BY '$panel_pw';
GRANT ALL PRIVILEGES ON $pelican_db.* TO '$panel_db_user'@'localhost';
FLUSH PRIVILEGES;
EOF
}

panel_repo(){

    sudo mkdir -p /var/www/pelican
    cd /var/www/pelican
    curl -L https://github.com/pelican-dev/panel/releases/latest/download/panel.tar.gz | sudo tar -xzv
    curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer
    sudo COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader
}

install_certbot(){

    sudo apt install -y python3-certbot-apache
}

panel_cert(){
    sudo apt install -y python3-certbot-apache
    certbot --apache \
    --non-interactive \
    --agree-tos \
    --redirect \
    --email "$certbot_mail" \
    -d "$panel_domain"
}

node_cert(){
    certbot --apache \
    --non-interactive \
    --agree-tos \
    --redirect \
    --email "$certbot_mail" \
    -d "$node_domain"
}

apache_config(){

    a2dissite 000-default default-ssl 000-default-le-ssl

    cat <<EOF > /etc/apache2/sites-available/pelican.conf
<VirtualHost *:80>
    ServerName $panel_domain

    RewriteEngine On
    RewriteCond %{HTTPS} !=on
    RewriteRule ^/?(.*) https://%{SERVER_NAME}/$1 [R,L] 
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

    sudo a2ensite pelican.conf
    sudo a2enmod ssl
    sudo a2enmod rewrite
    sudo a2enmod php8.4

    sudo systemctl restart apache2

}

enable_panel(){
    sudo systemctl restart apache2
    php artisan p:environment:setup
    sudo chmod -R 755 storage/* bootstrap/cache/
    sudo chown -R www-data:www-data /var/www/pelican
}

whip_panel(){

    panel_domain=$(whiptail --title "Panel Domain" --inputbox "What is your Panel Domain" 10 60 3>&1 1>&2 2>&3)

    certbot_mail=$(whiptail --title "Certbot E-Mail" --inputbox "Please enter your E-Mail" 10 60 3>&1 1>&2 2>&3)

    root_pw=$(whiptail --title "Create DB Password" \
    --passwordbox "What do you want as your Root Acc DB Password?" 10 60 3>&1 1>&2 2>&3)

    panel_pw=$(whiptail --title "Create DB Password for Panel Acc" \
    --passwordbox "What do you want as your Panel Acc DB Password?" 10 60 3>&1 1>&2 2>&3)

    pelican_db=$(whiptail --title "Panel Database Name" --inputbox "What you want to name your Panel Databse?" 10 60 "panel" 3>&1 1>&2 2>&3)

    panel_db_user=$(whiptail --title "Panel DB Username" --inputbox "What should be your DB Username for your Panel" 10 60 "pelican" 3>&1 1>&2 2>&3)

    whiptail --title "Overview" --msgbox "$(echo -e "Panel Domain: $panel_domain\nSSL Mail: $certbot_mail\nDatabase Type: MySQL\nPanel Database Password: $panel_pw\nPanel Database Name: $pelican_db\nRoot User DB Password: $root_pw\nDatabase User: $panel_db_user")" 15 60

}

whip_wings(){
    node_domain=$(whiptail --title "Node Domain" --inputbox "What is your Node Domain" 10 60 3>&1 1>&2 2>&3)

    certbot_mail=$(whiptail --title "Certbot E-Mail" --inputbox "Please enter your E-Mail" 10 60 3>&1 1>&2 2>&3)

    whiptail --title "Overview" --msgbox "$(echo -e "Node Domain: $node_domain\nSSL Mail: $certbot_mail")" 15 60
}

whip_both(){

     panel_domain=$(whiptail --title "Panel Domain" --inputbox "What is your Panel Domain" 10 60 3>&1 1>&2 2>&3)

    node_domain=$(whiptail --title "Node Domain" --inputbox "What is your Node Domain" 10 60 3>&1 1>&2 2>&3)

    certbot_mail=$(whiptail --title "Certbot E-Mail" --inputbox "Please enter your E-Mail" 10 60 3>&1 1>&2 2>&3)

    root_pw=$(whiptail --title "Create DB Password" \
    --passwordbox "What do you want as your Root Acc DB Password?" 10 60 3>&1 1>&2 2>&3)

    panel_pw=$(whiptail --title "Create DB Password for Panel Acc" \
    --passwordbox "What do you want as your Panel Acc DB Password?" 10 60 3>&1 1>&2 2>&3)

    pelican_db=$(whiptail --title "Panel Database Name" --inputbox "What you want to name your Panel Databse?" 10 60 "panel" 3>&1 1>&2 2>&3)

    panel_db_user=$(whiptail --title "Panel DB Username" --inputbox "What should be your DB Username for your Panel" 10 60 "pelican" 3>&1 1>&2 2>&3)

    whiptail --title "Overview" --msgbox "$(echo -e "Panel Domain: $panel_domain\nSSL Mail: $certbot_mail\nDatabase Type: MySQL\nPanel Database Password: $panel_pw\nPanel Database Name: $pelican_db\nRoot User DB Password: $panel_pw\nDatabase User: $panel_db_user")" 15 60

}
wings_repo(){

    curl -sSL https://get.docker.com/ | CHANNEL=stable sudo sh

    sudo mkdir -p /etc/pelican /var/run/wings
    sudo curl -L -o /usr/local/bin/wings "https://github.com/pelican-dev/wings/releases/latest/download/wings_linux_$([[ "$(uname -m)" == "x86_64" ]] && echo "amd64" || echo "arm64")"
    sudo chmod u+x /usr/local/bin/wings
}

systemcd_config(){

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
}

after_wings(){

    whiptail --title "Next Steps" --msgbox "Now go back to my repository and follow the steps\nafter the Wing installation to finish the\nPelican Panel installation." 12 60
}



installation=$(whiptail --title "Installation" \
  --menu "What do you want to install?" 15 60 4 \
  "1" "Panel" \
  "2" "Wings" \
  "3" "Both" \
  3>&1 1>&2 2>&3)

case "$installation" in
  1)
    whip_panel
    SystemUpdate
    InstallApache
    InstallPHP
    OtherDependencies
    MySQL
    panel_repo
    install_certbot
    apache_config
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
    whip_both
    SystemUpdate
    InstallApache
    InstallPHP
    OtherDependencies
    MySQL
    panel_repo
    install_certbot
    apache_config
    enable_panel
    node_cert
    wings_repo
    systemcd_config
    after_wings
    ;;
esac



