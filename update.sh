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


error_handler() {
    local exit_code=$?
    local line_number=$1
    local last_command="${BASH_COMMAND}"

    local msg=$(printf "Error in Line %s:\n\n%s\n\nExit-Code: %s" "$line_number" "$last_command" "$exit_code")
    whiptail --title "Error" --msgbox "$msg\nIf you dont know how to fix issue report it on the repository." 15 70
    exit "$exit_code"
}

set -euo pipefail
trap 'error_handler $LINENO' ERR

update_panel() {
  cd /var/www/pelican || {
    whiptail --title "Error" --msgbox "Directory /var/www/pelican not found" 10 60
    exit 1
  }

  php artisan down

  curl -L https://github.com/pelican-dev/panel/releases/latest/download/panel.tar.gz | sudo tar -xzv
  sudo chmod -R 755 storage/* bootstrap/cache
  sudo COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader
  php artisan storage:link
  php artisan view:clear
  php artisan config:clear
  php artisan filament:optimize
  php artisan migrate --seed --force
  sudo chown -R www-data:www-data /var/www/pelican
  php artisan queue:restart
  php artisan up
}

update_wings() {
  sudo systemctl stop wings
  sudo curl -L -o /usr/local/bin/wings "https://github.com/pelican-dev/wings/releases/latest/download/wings_linux_$([[ "$(uname -m)" == "x86_64" ]] && echo "amd64" || echo "arm64")"
  sudo chmod u+x /usr/local/bin/wings
  sudo systemctl restart wings
}

installation=$(whiptail --title "Update Pelican" \
  --menu "What do you want to update?" 15 60 4 \
  "1" "Panel" \
  "2" "Wings" \
  "3" "Both" \
  3>&1 1>&2 2>&3)

case "$installation" in
  1)
    update_panel
    whiptail --title "Panel updated" --msgbox "Your Panel is now succsesfully updated. Have fun" 12 60
    ;;
  2)
    update_wings
    whiptail --title "Wings updated" --msgbox "Your Wings were succsesfully updated. Have fun!" 12 60
    ;;
  3)
    update_panel
    update_wings
    whiptail --title "Update completed" --msgbox "Your Panel and Wings were succsesfully updated! Have Fun!" 12 60
    ;;
esac
