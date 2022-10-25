#!/usr/bin/env bash

# Read global script arguments
auto="n"

while getopts a: flag
do
    case "${flag}" in
        a) auto=${OPTARG};;
    esac
done

# Message function, show message with time
message () {
   now=$(date +"%T")
   echo $'\e[32m'"# [$now]"$'\e[0m'" $1 "
}

get () {
   now=$(date +"%T")
   if [[ "$2" == "auto" ]] && [[ "$auto" == "y" ]]
   then 
      echo $'\e[32m'"# [$now]"$'\e[0m'" $1: y"
      result="y"
   else
      read -p $'\e[32m'"# [$now]"$'\e[0m'" $1: " result
   fi
}

# Prepare function
prepareSetup () {
   # Check if installer run as root
   if [ "$EUID" -ne 0 ]
      then message "Please run uCrewInstaller as root"
      exit
   fi
}

# Prepare function
checkAccept () {
   # Check if installer run as root
   if [ "$1" == "y" ]
   then 
      result=true
   else
      result=false
   fi

   # If autoinstall is enabled
   if [[ "$auto" == "y" ]]
   then 
      result=true
   fi
}

# Basic setup function
basicSetup() {
   message "Welcome to uCrewInstaller"
   if [[ "$auto" == "y" ]]; then
      message "Auto mode is enabled"
   fi
   get "Do you want to intall uCrew? [y/n]" "auto"
   checkAccept $result
   if [ $result == false ]
   then
      message "Good bay!"
      exit
   fi
   # Update current repository
   apt -y update
}

# Setup git
gitSetup() {
   get "Do you want to intall git? [y/n]" "auto"
   checkAccept $result
   if [ $result != false ]
   then
      apt install -y git
   fi
}

# Setup apache2
apacheSetup() {
   get "Do you want to intall apache2? [y/n]" "auto"
   checkAccept $result
   if [ $result != false ]
   then
      apt install -y apache2
   fi
   get "Do you want to add apache2 to firewall? [y/n]" "auto"
   checkAccept $result
   if [ $result != false ]
   then
      ufw allow in "Apache"
   fi
}

# Setup MySql
mysqlSetup() {
   get "Do you want to intall MySQL server? [y/n]" "auto"
   checkAccept $result
   if [ $result != false ]
   then
      apt install -y mysql-server
   fi
}

# Setup php
phpSetup() {
   get "Do you want to intall PHP? [y/n]" "auto"
   checkAccept $result
   if [ $result != false ]
   then
      apt install -y php libapache2-mod-php php-mysql
   fi
}

softwareSetup() {
   basicSetup
   gitSetup
   apacheSetup
   mysqlSetup
   phpSetup
}

uCrewSetup() {
   apache2_configuration_file="/etc/apache2/sites-available/99-uCrew.conf"
   ucrew_repository="https://github.com/stellar-creator/uCrew.git"
   ucrew_location="/var/www/uCrew"
   ucrew_server="localhost"
   ucrew_port="80"
   ucrew_admin="admin@localhost"
   # Run configurator
   get "Do you want to intall uCrew with default configuration? [y/n]" "auto"
   checkAccept $result
   if [ $result == false ]
   then
      get "Remote uCrew repository"
      ucrew_repository=$result
      get "Local installation directory"
      ucrew_location=$result
      get "Server address"
      ucrew_server=$result
      get "Server administrator"
      ucrew_admin=$result
   fi  
   # Finish data prepare
   message "uCrew will be installed with next parameters:"
   message "Git repository: $ucrew_repository"
   message "Directory: $ucrew_location"
   message "Server address: $ucrew_server"
   message "Server port: $ucrew_port"
   message "Server administrator: $ucrew_admin"
   # Download last uCrew
   message "Download uCrew to $ucrew_location"
   git clone $ucrew_repository "$ucrew_location"
   message "Add uCrew to apache2 server"
   
   apache2_configuration="<VirtualHost *:$ucrew_port>
        ServerAdmin $ucrew_admin
        ServerName uCrew
        ServerAlias $ucrew_server
        DocumentRoot \"$ucrew_location/\"
        <Directory \"$ucrew_location/\">
                Options Indexes FollowSymLinks MultiViews
                AllowOverride All
                Order allow,deny
                allow from all
                Require all granted
                Header always set X-Frame-Options "SAMEORIGIN"
        </Directory>
        ErrorLog \${APACHE_LOG_DIR}/error.log
        CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>

# vim: syntax=apache ts=4 sw=4 sts=4 sr noet
"

   message "Write to $apache2_configuration_file"
   touch "$apache2_configuration_file"
   echo "$apache2_configuration" > "$apache2_configuration_file"
   message "Append apache2 configuration"
   a2ensite 99-uCrew
   message "Restart apache2"
   systemctl restart apache2
   get "Do you want to configure MySQL server? [y/n]" "auto"
   checkAccept $result
   if [ $result != false ]
   then
      mysql_secure_installation
   fi
   message "Setup is done! Please open in browser you uCrew."
}

# Run main script steps
prepareSetup
softwareSetup
uCrewSetup
