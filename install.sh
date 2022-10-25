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
   apt update
}

# Setup git
gitSetup() {
   get "Do you want to intall git? [y/n]" "auto"
   checkAccept $result
   if [ $result != false ]
   then
      apt install git
   fi
}

# Setup apache2
apacheSetup() {
   get "Do you want to intall apache2? [y/n]" "auto"
   checkAccept $result
   if [ $result != false ]
   then
      apt install apache2
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
      apt install mysql-server
   fi
   get "Do you want to configure MySQL server? [y/n]" "auto"
   checkAccept $result
   if [ $result != false ]
   then
      apt mysql_secure_installation
   fi
}

# Setup php
phpSetup() {
   get "Do you want to intall PHP? [y/n]" "auto"
   checkAccept $result
   if [ $result != false ]
   then
      apt install php libapache2-mod-php php-mysql
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
   ucrew_repository="http://192.168.0.10:3000/pavel/uCrew.git"
   ucrew_location="/var/www/uCrew"
   # Run configurator
   get "Do you want to intall uCrew with default configuration? [y/n]" "auto"
   checkAccept $result
   if [ $result == false ]
   then
      get "Remote uCrew repository"
      ucrew_repository=$result
      get "Local installation directory"
      ucrew_location=$result
   fi  
   # Finish data prepare
   message "uCrew will be installed with next parameters:"
   message "Git repository: $ucrew_repository"
   message "Directory: $ucrew_location"
   # Download last uCrew
   message "Download uCrew to $ucrew_location"
   git clone $ucrew_repository "$ucrew_location"
}

# Run main script steps
prepareSetup
softwareSetup
uCrewSetup
