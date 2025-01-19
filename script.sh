#!/bin/bash

# Reset
Color_Off='\033[0m'       # Text Reset
## Regular Colors
Black='\033[0;30m'        # Black
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan
White='\033[0;37m'        # White


staticIp() {
    echo -e "${Red}-------------------------------${Color_Off}"
    echo -e "${Yellow} IF YOU DON'T KNOW WHAT YOU ARE DOING STOP AND READ THE INSTRUCTIONS AT https://github.com/g-flame/rpi-setup/docs/ip.md ${Color_Off}"
    read -p "Continue ?[y/n]: " areYouSure
    case $areYouSure in
    y)
    sleep 10
    apt install network-manager -y
    nmcli connection
    echo -e "${Red}-------------------------------${Color_Off}"
    echo "   "
    echo -e "${Red}-------------------------------${Color_Off}"
    read -p "Enter the Connection name: " connectionName
    echo -e "${Red}-------------------------------${Color_Off}"
    echo "   "
    echo -e "${Red}-------------------------------${Color_Off}"
    echo "${Purple}Eg: 192.168.1.540/24${Color_Off}"
    read -p "Enter the IP for your device: " ipAddress
    echo "   "
    echo -e "${Red}-------------------------------${Color_Off}"
    echo "Eg: 192.168.1.1 (This is the router's admin page ip)"
    read -p "Enter the gateway ip for your Router: " ipGateWayAddress
    echo "   "

    ## actual execution of commands
     nmcli connection modify '$connectionName' ipv4.address $ipAddress
     echo "   "
     echo "   "
     echo "   "
     nmcli connection modify '$connectionName' ipv4.gateway $ipGateWayAddress
     echo "   "
     echo "   "
     echo "   "
     nmcli connection modify '$connectionName' ipv4.method manual
     echo "   "
     echo "   "
     echo "   "
     nmcli connection modify '$connectionName' ipv4.dns '8.8.8.8'
     echo "   "
     echo "   "
     echo "   "
     echo "YOU ARE GOING TO BE LOGGED OUT IF YOU ARE USING SSH! save your work or exit using 'ctrl + c'"
     sleep 5
     nmcli connection down '$connectionName' && nmcli connection up '$connectionName'
     echo "   "
     echo "   "
     echo "   "
     echo -e "The setup should be done !"
     echo "   "
     echo "   "
     echo "   "
     ;;
     n)
      esac
        ;;
}


## ui
asciiArt(){
 echo -e "----------------------------------------------------------------------"
 echo -e " _____   _____  _____        _____  ______  _______  _    _  _____    "
 echo -e " |  __ \ |  __ \|_   _|      / ____||  ____||__   __|| |  | ||  __ \  "
 echo -e " | |__) || |__) | | | ______| (___  | |__      | |   | |  | || |__) | "
 echo -e " |  _  / |  ___/  | ||______|\___ \ |  __|     | |   | |  | ||  ___/  "
 echo -e " | | \ \ | |     _| |_       ____) || |____    | |   | |__| || |      "
 echo -e " |_|  \_\|_|    |_____|     |_____/ |______|   |_|    \____/ |_|      "
 echo -e " Made By ${Green}g-flame${Color_Off} [https://github.com/g-flame]          v1.8.0.1.2.0.2.5 "
 echo -e"---------------------------------------------------------------------- "                                                                    
}

ui() {
    clear
    asciiArt
    echo -e "Available options  [options]"
    echo -e "                          []"
    echo -e "Setup Static ip         [ip]"
    echo -e "About                  [abt]"
    echo -e "Exit                  [exit]"

      read -p "what do you want to do ?: " choice
      case $choice in
      ## options
         # );; 
      ip)
        staticIp
        ui
        ;;
    exit)
        rm -rf /tmp/rpi-setup/
        esac
        ;;
    *)
        echo "   "
        echo "   "
        echo "   "
        echo -e "Enter a valid option!"
        echo "   "
        echo "   "
        echo "   "
        ui 
        ;;

}

## calling ui and checkin root

    if [ "$EUID" -ne 0 ]; then
    echo -e "${Red}Please run with root account or use sudo to start the script!${Color_Off}"
    exit 1
    fi 

ui

## checing for ^c and deleting tmp dor
trap "echo Script Interrupted" SIGINT
rm -rf /tmp/rpi-setup/
[ "$?" = 130 ] && echo "  Closing script!  "
esac 