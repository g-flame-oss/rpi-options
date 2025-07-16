#!/bin/bash

# RPI Network Setup Script - Optimized Version
# Version: 2.0.0 - Made by g-flame

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

TEMP_FILE=$(mktemp)

# Cleanup on exit
cleanup() {
    rm -f "$TEMP_FILE"
    clear
    echo -e "${GREEN}Script terminated.${NC}"
    exit 0
}

trap cleanup EXIT SIGINT SIGTERM

# Check root privileges
check_root() {
    [ "$EUID" -ne 0 ] && { echo -e "${RED}Please run with root privileges (sudo)!${NC}"; exit 1; }
}

# Install dialog if missing
check_dialog() {
    ! command -v dialog &> /dev/null && { echo -e "${YELLOW}Installing dialog...${NC}"; apt update && apt install dialog -y; }
}

# Check/install network manager
check_network_manager() {
    if ! command -v nmcli &> /dev/null; then
        dialog --title "Network Manager" --yesno "Network Manager is not installed. Install it now?" 8 50
        [ $? -eq 0 ] && { clear; echo -e "${YELLOW}Installing Network Manager...${NC}"; apt update && apt install network-manager -y; } || return 1
    fi
}

# Network helper functions
get_interfaces() { nmcli -t -f NAME connection show | grep -v "lo"; }

get_current_config() { nmcli connection show "$1" | grep -E "ipv4\.(address|gateway|dns|method)"; }

# Validate IP address format
validate_ip() {
    local ip="$1"
    [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}(/[0-9]{1,2})?$ ]] || return 1
    IFS='.' read -r -a octets <<< "${ip%/*}"
    for octet in "${octets[@]}"; do
        [ "$octet" -gt 255 ] && return 1
    done
}

# Configure static IP address
configure_static_ip() {
    check_network_manager || return 1
    
    # Get available interfaces
    local interfaces=$(get_interfaces)
    [ -z "$interfaces" ] && { dialog --title "Error" --msgbox "No network interfaces found!" 8 50; return 1; }

    # Build interface menu
    local menu_items=() count=1
    while IFS= read -r interface; do
        menu_items+=("$count" "$interface")
        count=$((count + 1))
    done <<< "$interfaces"

    # Select interface
    dialog --title "Network Interface" --menu "Select network interface:" 15 50 8 "${menu_items[@]}" 2> "$TEMP_FILE"
    [ $? -ne 0 ] && return 1

    local selected_num=$(cat "$TEMP_FILE")
    local selected_interface=$(echo "$interfaces" | sed -n "${selected_num}p")
    local current_config=$(get_current_config "$selected_interface")
    
    # Show current config and warning
    dialog --title "Current Configuration" --msgbox "Interface: $selected_interface\n\n$current_config" 15 70
    dialog --title "Warning" --yesno "Configuring static IP will change your network settings.\nYou may lose SSH connection if connected remotely.\n\nContinue?" 10 60
    [ $? -ne 0 ] && return 1

    # Get IP address
    while true; do
        dialog --title "IP Address" --inputbox "Enter IP address with subnet (e.g., 192.168.1.100/24):" 10 60 2> "$TEMP_FILE"
        [ $? -ne 0 ] && return 1
        local ip_address=$(cat "$TEMP_FILE")
        validate_ip "$ip_address" && break
        dialog --title "Error" --msgbox "Invalid IP address format!" 8 50
    done

    # Get gateway
    while true; do
        dialog --title "Gateway" --inputbox "Enter gateway IP address (e.g., 192.168.1.1):" 10 60 2> "$TEMP_FILE"
        [ $? -ne 0 ] && return 1
        local gateway=$(cat "$TEMP_FILE")
        validate_ip "$gateway" && break
        dialog --title "Error" --msgbox "Invalid gateway IP address!" 8 50
    done

    # Get DNS servers
    dialog --title "DNS Servers" --inputbox "Enter DNS servers (comma-separated, e.g., 8.8.8.8,8.8.4.4):" 10 60 "8.8.8.8,8.8.4.4" 2> "$TEMP_FILE"
    [ $? -ne 0 ] && return 1
    local dns_servers=$(cat "$TEMP_FILE")

    # Confirm settings
    dialog --title "Confirmation" --yesno "Apply these settings?\n\nInterface: $selected_interface\nIP Address: $ip_address\nGateway: $gateway\nDNS: $dns_servers" 12 60
    [ $? -ne 0 ] && return 1

    # Apply configuration
    clear
    echo -e "${YELLOW}Applying network configuration...${NC}"
    
    nmcli connection modify "$selected_interface" ipv4.address "$ip_address"
    nmcli connection modify "$selected_interface" ipv4.gateway "$gateway"
    nmcli connection modify "$selected_interface" ipv4.method manual
    nmcli connection modify "$selected_interface" ipv4.dns "$dns_servers"
    
    echo -e "${YELLOW}Restarting network connection...${NC}"
    echo -e "${RED}Warning: You may lose connection if using SSH!${NC}"
    sleep 3
    
    nmcli connection down "$selected_interface" && nmcli connection up "$selected_interface"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Network configuration applied successfully!${NC}"
        echo -e "${GREEN}New IP address: $ip_address${NC}"
    else
        echo -e "${RED}Failed to apply network configuration!${NC}"
    fi
    
    echo -e "${YELLOW}Press any key to continue...${NC}"
    read -n 1
}

# Display network status
show_network_status() {
    local status=$(nmcli device status)
    local connections=$(nmcli connection show)
    dialog --title "Network Status" --msgbox "Device Status:\n$status\n\nConnections:\n$connections" 20 80
}

# Show about dialog
show_about() {
    dialog --title "About" --msgbox "RPI Network Setup Script\n\nVersion: 2.0.0\nMade by: g-flame\nGitHub: https://github.com/g-flame\n\nThis script helps configure static IP addresses on Raspberry Pi using NetworkManager." 12 60
}

# Empty function for GfDE setup
rpi-gfde() {
    echo "i am implementing it soon..."
}

# Main menu loop
main_menu() {
    while true; do
        dialog --title "RPI Network Setup" --menu "Choose an option:" 15 60 5 \
            1 "Configure Static IP" \
            2 "Show Network Status" \
            3 "Setup GfDE for Rpi" \
            4 "About" \
            5 "Exit" 2> "$TEMP_FILE"
        
        case $? in
            0)
                choice=$(cat "$TEMP_FILE")
                case $choice in
                    1) configure_static_ip ;;
                    2) show_network_status ;;
                    3) rpi-gfde ;;
                    4) show_about ;;
                    5) exit 0 ;;
                esac
                ;;
            1|255) exit 0 ;;
        esac
    done
}

# Main function
main() {
    check_root
    check_dialog
    main_menu
}

main