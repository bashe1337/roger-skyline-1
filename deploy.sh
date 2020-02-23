#!/bin/sh


COLOR_INFO="\033[0;36m"
COLOR_ERR="\033[0;31m"
COLOR_RESET="\033[0m"
GIT="/home/roger/roger-skyline-1/src"

error () {
echo -e ${COLOR_ERR}${PRE_ERR}${1}${COLOR_RESET}
}

error_exit () {
error "Fail... exiting"
exit
}

info () {
echo -e "${COLOR_INFO}${PRE_INFO}${1}${COLOR_RESET}"
}

info "Updating system"
sudo apt update || error_exit

info "Upgrading system"
sudo apt upgrade || error_exit

# Configure static IP address
info "Change to static IP"
sudo cp $GIT/interfaces /etc/network/interfaces
sudo service networking restart || error "Fail with networking"

# Configure ssh
info "Configure ssh"
sudo $GIT/ssh/sshd_config /etc/ssh/sshd_config
sudo service ssh restart || error "Fail with SSH"

# Configure ufw
sudo apt install ufw
sudo ufw enable
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https
sudo ufw allow 52202

# Configure fail2ban
sudo apt install fail2ban
sudo apt install iptables
info "Deploying fail2ban"
sudo cp $GIT/fail2ban/jail.local /etc/fail2ban/jail.local
sudo cp $GIT/fail2ban/http-get-dos.conf /etc/fail2ban/filter.d/http-get-dos.conf
sudo service fail2ban restart || error "Fail with fail2ban"
info "fail2ban status"
sudo fail2ban-client status

# Portsentry
info "Configure portsentry"
sudo apt install portsentry
sudo cp $GIT/portsentry/portsentry /etc/default/portsentry
sudo cp $GIT/portsentry/portsentry.conf /etc/portsentry/portsentry.conf

# Stop services
info "Stop services"
sudo systemctl disable console-setup.service
sudo systemctl disable keyboard-setup.service

# Scripts and cron
info "Scripts and cron"
sudo chmod +x $GIT/scripts/update.sh
sudo chmod +x $GIT/scripts/monitor_cron.sh
sudo cp $GIT/scripts/update.sh /etc/cron.d/update.sh || error "Fail with update.sh"
sudo cp $GIT/scripts/monitor_cron.sh /etc/cron.d/monitor_cron.sh || error "Fail with monitor_cron.sh"
sudo cp $GIT/cron/crontab /etc/crontab || error "Fail with crontab"
sed -i "/^[[:blank:]]*root:[[:blank:]]*[[:graph:]]*[[:blank:]]*$/c\root: root" /etc/aliases
sudo newaliases || error "Fail with newaliases"

# Mail
sudo apt install mailutils
sudo apt install postfix


# Install apache2
info "Installing Apache"
sudo apt install apache2
sudo cp $GIT/html/index.html /var/www/html/index.html

# Generate SSL and configure apache
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/apache-selfsigned.key -out /etc/ssl/certs/apache-selfsigned.crt
sudo cp $GIT/ssl/ssl-params.conf /etc/apache2/conf-available/ssl-params.conf || error "Fail with ssl-params.conf"
sudo cp $GIT/ssl/default-ssl.conf /etc/apache2/sites-available/default-ssl.conf || error "Fail with default-ssl.conf"
sudo cp $GIT/ssl/000-default.conf /etc/apache2/sites-available/000-default.conf || error "000-default.conf"

sudo a2enmod ssl
sudo a2enmod headers
sudo a2ensite default-ssl
sudo apache2ctl configtest
info "Restarting Apache"
sudo systemctl restart apache2
sudo reboot
