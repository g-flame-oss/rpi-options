#!/bin/bash

# Reset
Color_Off='\033[0m'       # Text Reset
# Regular Colors
Black='\033[0;30m'        # Black
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan
White='\033[0;37m'        # White

# Check if script is run as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${Red}Please run with root account or use sudo to start the script!${Color_Off}"
        exit 1
    fi
}

# Function to validate IP address
validate_ip() {
    local ip=$1
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,2}$ ]]; then
        return 0
    fi
    return 1
}

# Configure static IP
setup_static_ip() {
    echo -e "${Red}-------------------------------${Color_Off}"
    echo -e "${Yellow}IF YOU DON'T KNOW WHAT YOU ARE DOING STOP AND READ THE INSTRUCTIONS AT https://github.com/g-flame/rpi-setup/docs/ip.md${Color_Off}"
    read -p "Continue? [y/n]: " are_you_sure
    
    case $are_you_sure in
        [yY])
            echo "Installing network-manager..."
            apt install network-manager -y || {
                echo "Failed to install network-manager"
                return 1
            }
            
            nmcli connection

            echo -e "${Red}-------------------------------${Color_Off}"
            read -p "Enter the Connection name: " connection_name
            
            echo -e "${Red}-------------------------------${Color_Off}"
            echo -e "${Purple}Example: 192.168.1.100/24${Color_Off}"
            while true; do
                read -p "Enter the IP for your device: " ip_address
                if validate_ip "$ip_address"; then
                    break
                else
                    echo "Invalid IP address format. Please try again."
                fi
            done
            
            echo -e "${Red}-------------------------------${Color_Off}"
            echo "Example: 192.168.1.1 (This is the router's admin page IP)"
            read -p "Enter the gateway IP for your Router: " gateway_ip

            # Configure network
            echo "Configuring network settings..."
            nmcli connection modify "$connection_name" ipv4.address "$ip_address" || {
                echo "Failed to set IP address"
                return 1
            }
            
            nmcli connection modify "$connection_name" ipv4.gateway "$gateway_ip" || {
                echo "Failed to set gateway"
                return 1
            }
            
            nmcli connection modify "$connection_name" ipv4.method manual || {
                echo "Failed to set manual method"
                return 1
            }
            
            nmcli connection modify "$connection_name" ipv4.dns "8.8.8.8" || {
                echo "Failed to set DNS"
                return 1
            }

            echo "YOU ARE GOING TO BE LOGGED OUT IF YOU ARE USING SSH! Save your work or exit using 'ctrl + c'"
            sleep 5
            
            nmcli connection down "$connection_name" && nmcli connection up "$connection_name" || {
                echo "Failed to restart connection"
                return 1
            }

            echo -e "${Green}Static IP setup completed successfully!${Color_Off}"
            ;;
        *)
            echo "Operation cancelled"
            ;;
    esac
}

# ASCII art banner
show_banner() {
    echo -e "----------------------------------------------------------------------"
    echo -e " _____   _____  _____        _____  ______  _______  _    _  _____    "
    echo -e " |  __ \ |  __ \|_   _|      / ____||  ____||__   __|| |  | ||  __ \  "
    echo -e " | |__) || |__) | | | ______| (___  | |__      | |   | |  | || |__) | "
    echo -e " |  _  / |  ___/  | ||______|\___ \ |  __|     | |   | |  | ||  ___/  "
    echo -e " | | \ \ | |     _| |_       ____) || |____    | |   | |__| || |      "
    echo -e " |_|  \_\|_|    |_____|     |_____/ |______|   |_|    \____/ |_|      "
    echo -e " Made By ${Green}g-flame${Color_Off} [https://github.com/g-flame]          v1.8.0.1.2.0.2.5 "
    echo -e "----------------------------------------------------------------------"
}

# Main menu
show_menu() {
    clear
    show_banner
    echo -e "Available options:"
    echo -e "Setup Static IP         [ip]"
    echo -e "About                  [abt]"
    echo -e "Exit                  [exit]"

    read -p "What do you want to do?: " choice
    case $choice in
        ip)
            setup_static_ip
            show_menu
            ;;
        exit)
            echo "Cleaning up..."
            rm -rf /tmp/rpi-setup/
            exit 0
            ;;
        *)
            echo -e "\nEnter a valid option!"
            sleep 2
            show_menu
            ;;
    esac
}

# Handle script interruption
cleanup() {
    echo -e "\nScript interrupted"
    rm -rf /tmp/rpi-setup/
    exit 130
}

trap cleanup SIGINT

# Main execution
check_root
show_menu
