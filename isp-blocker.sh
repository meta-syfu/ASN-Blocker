#!/bin/bash

# Colors for output
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
ENDCOLOR="\e[0m"

# Array of ISPs and URLs to download IP lists
declare -A ISPS
ISPS=(
    ["asiatech"]="https://raw.githubusercontent.com/meta-syfu/ASN-Blocker/master/asiatech.ipv4"
    ["mci"]="https://raw.githubusercontent.com/meta-syfu/ASN-Blocker/master/mci.ipv4"
    ["mobinnet"]="https://raw.githubusercontent.com/meta-syfu/ASN-Blocker/master/mobinnet.ipv4"
    ["mtn"]="https://raw.githubusercontent.com/meta-syfu/ASN-Blocker/master/mtn.ipv4"
    ["parsan"]="https://raw.githubusercontent.com/meta-syfu/ASN-Blocker/master/parsan.ipv4"
    ["pishgaman"]="https://raw.githubusercontent.com/meta-syfu/ASN-Blocker/master/pishgaman.ipv4"
    ["ritel"]="https://raw.githubusercontent.com/meta-syfu/ASN-Blocker/master/ritel.ipv4"
    ["shatel"]="https://raw.githubusercontent.com/meta-syfu/ASN-Blocker/master/shatel.ipv4"
    ["tci"]="https://raw.githubusercontent.com/meta-syfu/ASN-Blocker/master/tci.ipv4"
)

# Create /etc/iptables directory if it does not exist
mkdir -p /etc/iptables

# Function to download IP lists
download_ip_list() {
    ISP_NAME=$1
    URL=${ISPS[$ISP_NAME]}
    DEST="/etc/iptables/${ISP_NAME}.ipv4"

    echo -e "${YELLOW}Downloading IP list for ${ISP_NAME}...${ENDCOLOR}"
    curl -s "$URL" -o "$DEST"

    if [ $? -eq 0 ] && [ -s "$DEST" ]; then
        echo -e "${GREEN}${ISP_NAME} IP list downloaded successfully.${ENDCOLOR}"
    else
        echo -e "${RED}Failed to download ${ISP_NAME} IP list or the file is empty.${ENDCOLOR}"
        return 1
    fi
}

# Function to configure ports for specific ISP
configure_ports_for_isp() {
    PORT=$1
    ISP_NAME=$2
    echo -e "${YELLOW}Configuring port ${PORT} for ISP ${ISP_NAME}...${ENDCOLOR}"

    if [ ! -f "/etc/iptables/${ISP_NAME}.ipv4" ]; then
        echo -e "${RED}IP list for ${ISP_NAME} not found. Downloading...${ENDCOLOR}"
        download_ip_list "$ISP_NAME"
        if [ $? -ne 0 ]; then
            echo -e "${RED}Failed to configure port ${PORT} for ISP ${ISP_NAME} due to missing IP list.${ENDCOLOR}"
            return
        fi
    fi

    # Apply ufw rules
    while read -r IP; do
        if [ -n "$IP" ]; then
            sudo ufw allow from "$IP" to any port "$PORT" proto tcp
        fi
    done < "/etc/iptables/${ISP_NAME}.ipv4"

    echo -e "${GREEN}Port ${PORT} configured for ISP ${ISP_NAME}.${ENDCOLOR}"
}

# Function to configure always open ports for all ISPs
configure_always_open_ports() {
    PORTS=$1
    IFS=',' read -ra PORT_ARRAY <<< "$PORTS"

    for PORT in "${PORT_ARRAY[@]}"; do
        echo -e "${YELLOW}Opening port ${PORT} for all ISPs...${ENDCOLOR}"
        sudo ufw allow "$PORT"/tcp
        echo -e "${GREEN}Port ${PORT} is open for all ISPs.${ENDCOLOR}"
    done
}

# Function to clear all ufw rules
clear_all_config() {
    echo -e "${YELLOW}Clearing all ufw rules...${ENDCOLOR}"
    sudo ufw reset
    echo -e "${GREEN}All ufw rules have been cleared.${ENDCOLOR}"
}

# Function to list ISPs and let the user select one
select_isp() {
    echo "Select an ISP:"
    select ISP_NAME in "${!ISPS[@]}"; do
        if [[ -n "${ISPS[$ISP_NAME]}" ]]; then
            echo -e "${YELLOW}You selected ${ISP_NAME}.${ENDCOLOR}"
            break
        else
            echo -e "${RED}Invalid selection, please try again.${ENDCOLOR}"
        fi
    done
    echo "$ISP_NAME"
}

# Main menu function
main_menu() {
    clear
    echo "==================== ISP Blocker ===================="
    echo "1) Configure ports for specific ISPs"
    echo "2) Configure always open ports"
    echo "3) Clear all ufw configurations"
    echo "4) Exit"
    echo "====================================================="
    echo -n "Please select an option: "
    read OPTION

    case $OPTION in
        1)
            echo -n "Enter the ports (comma-separated) to configure for specific ISPs: "
            read PORTS
            IFS=',' read -ra PORT_ARRAY <<< "$PORTS"

            for PORT in "${PORT_ARRAY[@]}"; do
                ISP_NAME=$(select_isp)
                configure_ports_for_isp "$PORT" "$ISP_NAME"
            done
            echo "Press enter to return to the menu..."
            read
            main_menu
            ;;
        2)
            echo -n "Enter ports to keep open for all connections (comma-separated): "
            read ALWAYS_OPEN_PORTS
            configure_always_open_ports "$ALWAYS_OPEN_PORTS"
            echo "Press enter to return to the menu..."
            read
            main_menu
            ;;
        3)
            clear_all_config
            echo "Press enter to return to the menu..."
            read
            main_menu
            ;;
        4)
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option, please try again.${ENDCOLOR}"
            main_menu
            ;;
    esac
}

# Enable ufw if not already enabled
enable_firewall() {
    echo -e "${YELLOW}Enabling ufw...${ENDCOLOR}"
    sudo ufw enable
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}ufw enabled successfully.${ENDCOLOR}"
    else
        echo -e "${RED}Failed to enable ufw.${ENDCOLOR}"
    fi
}

# Run the menu
enable_firewall
main_menu
