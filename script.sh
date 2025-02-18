#!/bin/bash

# Script Version
VERSION="2.1.0"

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

# Progress logging functions
log_progress() {
    echo -e "${Blue}[INFO]${Color_Off} $1"
}

log_success() {
    echo -e "${Green}[SUCCESS]${Color_Off} $1"
}

log_warning() {
    echo -e "${Yellow}[WARNING]${Color_Off} $1"
}

log_error() {
    echo -e "${Red}[ERROR]${Color_Off} $1"
}

# Detect OS and package manager
detect_system() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v apt-get &>/dev/null; then
            echo "debian"
        elif command -v dnf &>/dev/null; then
            echo "fedora"
        elif command -v pacman &>/dev/null; then
            echo "arch"
        else
            echo "unknown"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    else
        echo "unknown"
    fi
}

# Check if script is run as root
check_root() {
    if [[ "$(detect_system)" != "macos" ]]; then
        if [ "$EUID" -ne 0 ]; then
            log_error "Please run with root account or use sudo to start the script!"
            exit 1
        fi
    fi
}

# Function to validate IP address format
validate_ip_format() {
    local ip=$1
    local no_cidr=${ip%/*}
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}(/[0-9]{1,2})?$ ]]; then
        local IFS='.'
        read -ra ADDR <<< "$no_cidr"
        for i in "${ADDR[@]}"; do
            if [ $i -lt 0 ] || [ $i -gt 255 ]; then
                return 1
            fi
        done
        if [[ $ip == */* ]]; then
            local mask="${ip#*/}"
            if [ $mask -lt 0 ] || [ $mask -gt 32 ]; then
                return 1
            fi
        fi
        return 0
    fi
    return 1
}

# Function to validate gateway IP
validate_gateway() {
    local gateway=$1
    local ip=$2
    
    # Extract network address from IP/CIDR
    local network=$(ipcalc -n "$ip" | grep "Network:" | awk '{print $2}')
    local gateway_network=$(ipcalc -n "$gateway/24" | grep "Network:" | awk '{print $2}')
    
    if [ "$network" = "$gateway_network" ]; then
        return 0
    fi
    return 1
}

# Function to check network interface status
check_interface_status() {
    local interface=$1
    if ! ip link show "$interface" &>/dev/null; then
        return 1
    fi
    if [[ $(ip link show "$interface" | grep "state UP") ]]; then
        return 0
    fi
    return 2
}

# Function to backup network configuration
backup_network_config() {
    local backup_dir="/root/network_backup_$(date +%Y%m%d_%H%M%S)"
    log_progress "Creating network configuration backup in $backup_dir"
    
    mkdir -p "$backup_dir"
    if [[ -d "/etc/NetworkManager" ]]; then
        cp -r "/etc/NetworkManager" "$backup_dir/"
    fi
    if [[ -d "/etc/network" ]]; then
        cp -r "/etc/network" "$backup_dir/"
    fi
    
    log_success "Backup created successfully"
}

# Install network manager based on OS
install_network_manager() {
    local system=$(detect_system)
    log_progress "Installing network manager for $system..."
    
    case $system in
        "debian")
            apt update && apt install network-manager ipcalc -y
            ;;
        "fedora")
            dnf install NetworkManager ipcalc -y
            ;;
        "arch")
            pacman -S networkmanager ipcalc --noconfirm
            ;;
        "macos")
            log_warning "NetworkManager not required for macOS"
            return 0
            ;;
        *)
            log_error "Unsupported system for automatic NetworkManager installation"
            return 1
            ;;
    esac
    
    # Start and enable NetworkManager service
    systemctl start NetworkManager
    systemctl enable NetworkManager
    
    log_success "NetworkManager installation completed"
}

# Enhanced setup_static_ip function
setup_static_ip() {
    local system=$(detect_system)
    
    echo -e "${Yellow}=== Static IP Configuration ===${Color_Off}"
    log_warning "Please read the documentation carefully before proceeding:"
    echo -e "${Cyan}https://github.com/g-flame/rpi-setup/docs/ip.md${Color_Off}"
    read -p "Continue with setup? [y/N]: " are_you_sure
    
    case $are_you_sure in
        [yY])
            # Create backup before making changes
            backup_network_config
            
            if [[ "$system" != "macos" ]]; then
                # Install dependencies
                log_progress "Installing required packages..."
                install_network_manager || {
                    log_error "Failed to install network manager"
                    return 1
                }
                
                # List available connections
                log_progress "Available network connections:"
                echo -e "${Cyan}"
                nmcli -t -f NAME,TYPE,DEVICE connection show | column -t -s ':'
                echo -e "${Color_Off}"
                
                # Get connection name
                while true; do
                    read -p "Enter connection name: " connection_name
                    if nmcli connection show "$connection_name" &>/dev/null; then
                        break
                    else
                        log_error "Connection '$connection_name' not found. Please try again."
                    fi
                done
                
                # Get interface name
                interface=$(nmcli -t -f DEVICE connection show "$connection_name")
                if ! check_interface_status "$interface"; then
                    log_error "Interface $interface is not active"
                    return 1
                fi
                
                # Get IP address
                while true; do
                    echo -e "\n${Yellow}IP Address Format Examples:${Color_Off}"
                    echo "- 192.168.1.100/24 (typical home network)"
                    echo "- 10.0.0.100/24 (typical office network)"
                    read -p "Enter IP address with subnet mask (e.g., 192.168.1.100/24): " ip_address
                    
                    if validate_ip_format "$ip_address"; then
                        break
                    else
                        log_error "Invalid IP address format. Please try again."
                    fi
                done
                
                # Get gateway IP
                while true; do
                    echo -e "\n${Yellow}Gateway IP Examples:${Color_Off}"
                    echo "- 192.168.1.1 (typical home router)"
                    echo "- 10.0.0.1 (typical office router)"
                    read -p "Enter gateway IP: " gateway_ip
                    
                    if validate_ip_format "$gateway_ip"; then
                        if validate_gateway "$gateway_ip" "$ip_address"; then
                            break
                        else
                            log_error "Gateway IP is not in the same network as your IP address"
                        fi
                    else
                        log_error "Invalid gateway IP format. Please try again."
                    fi
                done
                
                # Configure DNS servers
                read -p "Use custom DNS servers? [y/N]: " use_custom_dns
                if [[ $use_custom_dns =~ ^[Yy]$ ]]; then
                    read -p "Enter primary DNS (default: 8.8.8.8): " primary_dns
                    read -p "Enter secondary DNS (default: 1.1.1.1): " secondary_dns
                    primary_dns=${primary_dns:-"8.8.8.8"}
                    secondary_dns=${secondary_dns:-"1.1.1.1"}
                else
                    primary_dns="8.8.8.8"
                    secondary_dns="1.1.1.1"
                fi
                
                # Apply configuration
                log_progress "Applying network configuration..."
                {
                    nmcli connection modify "$connection_name" ipv4.addresses "$ip_address" && \
                    nmcli connection modify "$connection_name" ipv4.gateway "$gateway_ip" && \
                    nmcli connection modify "$connection_name" ipv4.dns "$primary_dns,$secondary_dns" && \
                    nmcli connection modify "$connection_name" ipv4.method manual
                } || {
                    log_error "Failed to apply network configuration"
                    return 1
                }
                
                # Warn about connection reset
                log_warning "Network connection will be reset. If using SSH, you may be disconnected."
                log_warning "New IP address will be: ${ip_address%/*}"
                read -p "Continue? [y/N]: " confirm
                
                if [[ $confirm =~ ^[Yy]$ ]]; then
                    log_progress "Applying changes..."
                    if nmcli connection down "$connection_name" && nmcli connection up "$connection_name"; then
                        log_success "Static IP configuration completed successfully!"
                        echo -e "\n${Green}New network configuration:${Color_Off}"
                        echo "IP Address: $ip_address"
                        echo "Gateway: $gateway_ip"
                        echo "DNS: $primary_dns, $secondary_dns"
                    else
                        log_error "Failed to restart network connection"
                        return 1
                    fi
                else
                    log_warning "Configuration cancelled by user"
                    return 0
                fi
            else
                log_warning "macOS configuration not implemented"
                return 1
            fi
            ;;
        *)
            log_warning "Operation cancelled by user"
            return 0
            ;;
    esac
}

# ASCII art banner with progress spinner
show_banner() {
    clear
    echo -e "----------------------------------------------------------------------"
    echo -e " _____   _____  _____        _____  ______  _______  _    _  _____    "
    echo -e " |  __ \ |  __ \|_   _|      / ____||  ____||__   __|| |  | ||  __ \  "
    echo -e " | |__) || |__) | | | ______| (___  | |__      | |   | |  | || |__) | "
    echo -e " |  _  / |  ___/  | ||______|\___ \ |  __|     | |   | |  | ||  ___/  "
    echo -e " | | \ \ | |     _| |_       ____) || |____    | |   | |__| || |      "
    echo -e " |_|  \_\|_|    |_____|     |_____/ |______|   |_|    \____/ |_|      "
    echo -e " Made By ${Green}g-flame${Color_Off} [https://github.com/g-flame]                v$VERSION "
    echo -e "----------------------------------------------------------------------"
    echo -e "Running on: $(detect_system)"
}

# Main menu
show_menu() {
    show_banner
    echo -e "\nAvailable options:"
    echo -e "${Cyan}1.${Color_Off} Setup Static IP         ${Green}[ip]${Color_Off}"
    echo -e "${Cyan}2.${Color_Off} About                  ${Green}[abt]${Color_Off}"
    echo -e "${Cyan}3.${Color_Off} Exit                   ${Green}[exit]${Color_Off}"

    read -p "What do you want to do?: " choice
    case $choice in
        ip|1)
            setup_static_ip
            show_menu
            ;;
        abt|2)
            echo -e "\nRPI Setup Script v$VERSION"
            echo -e "A utility to configure Raspberry Pi and Linux systems"
            echo -e "GitHub: https://github.com/g-flame/rpi-setup"
            read -p "Press Enter to continue..."
            show_menu
            ;;
        exit|3)
            log_progress "Cleaning up..."
            rm -rf /tmp/network-setup/ 2>/dev/null
            log_success "Goodbye!"
            exit 0
            ;;
        *)
            log_error "Invalid option!"
            sleep 2
            show_menu
            ;;
    esac
}

# Handle script interruption
cleanup() {
    echo -e "\n"
    log_warning "Script interrupted"
    rm -rf /tmp/network-setup/ 2>/dev/null
    exit 130
}

trap cleanup SIGINT

# Main execution
check_root
show_menu
