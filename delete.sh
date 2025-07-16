#!/bin/bash

# Farben für whiptail (optional)
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

delete_panel_mysql() {
  whiptail --title "DB Deletion" --yesno "Do you want to delete your Panel DB?" 10 60

  if [ $? -eq 0 ]; then
    pelican_db=$(whiptail --title "Panel Database Name" --inputbox "What is the name of your Panel DB?" 10 60 "panel" 3>&1 1>&2 2>&3)
    panel_db_user=$(whiptail --title "Panel DB Username" --inputbox "What is your Panel DB Username?" 10 60 "pelican" 3>&1 1>&2 2>&3)
    root_pw=$(whiptail --title "Root Password" --passwordbox "What is your SQL Root Password" 10 60 3>&1 1>&2 2>&3)

    mysql -u root -p"$root_pw" <<EOF
DROP DATABASE IF EXISTS \`$pelican_db\`;
DROP USER IF EXISTS '$panel_db_user'@'localhost';
EOF
  fi
}

delete_panel_volumes() {
  whiptail --title "Volume Deletion" --yesno "Do you want to delete your Volumes with all your Server files and Backups?" 10 60

  if [ $? -eq 0 ]; then
    sudo rm -rf /var/lib/pelican
  fi
}

delete_panel() {
  sudo rm -rf /var/www/pelican

  sudo rm -f /etc/apache2/sites-enabled/pelican.conf
  sudo rm -f /etc/apache2/sites-available/pelican.conf

  sudo systemctl restart apache2

  sudo systemctl disable --now pelican-queue
  sudo rm -f /etc/systemd/system/pelican-queue.service
}

delete_wings() {
  sudo systemctl disable --now wings
  sudo rm -f /etc/systemd/system/wings.service
  sudo rm -f /usr/local/bin/wings
  sudo rm -rf /etc/pelican
}

# Auswahlmenü
installation=$(whiptail --title "Remove" \
  --menu "What do you want to remove?" 15 60 4 \
  "1" "Panel" \
  "2" "Wings" \
  "3" "Both" \
  3>&1 1>&2 2>&3)

case "$installation" in
  1)
    delete_panel_mysql
    delete_panel_volumes
    delete_panel

    whiptail --title "Succsess" --msgbox "Your Panel was succesfully deleted from your System" 10 60
    ;;
  2)
    delete_wings

    whiptail --title "Succsess" --msgbox "Your Wings were succesfully deleted from your System" 10 60
    ;;
  3)
    delete_panel_mysql
    delete_panel_volumes
    delete_panel
    delete_wings
    whiptail --title "Success" --msgbox "Your Panel and Wings were successfully deleted from your system." 10 60
    ;;
esac
