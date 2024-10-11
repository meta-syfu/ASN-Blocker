#!/bin/bash

# Colors
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
ENDCOLOR="\e[0m"

# Function to download IP lists
download_ip_list() {
    ISP_NAME=$1
    URL="https://raw.githubusercontent.com/meta-syfu/ASN-Blocker/refs/heads/master/${ISP_NAME}.ipv4"
    DEST="/etc/iptables/${ISP_NAME}.ipv4"

    echo -e "${YELLOW}Downloading IP list for ${ISP_NAME} from ${URL}...${ENDCOLOR}"
    curl -s "$URL" -o "$DEST"

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}${ISP_NAME} IP list downloaded successfully.${ENDCOLOR}"
    else
        echo -e "${RED}Failed to download ${ISP_NAME} IP list.${ENDCOLOR}"
    fi
}

# Create /etc/iptables directory if it does not exist
mkdir -p /etc/iptables

# Array of ISPs
ISPS=("asiatech" "mci" "mobinnet" "mtn" "parsan" "pishgaman" "ritel" "shatel" "tci")

# Download IP lists for all ISPs
for ISP in "${ISPS[@]}"; do
    download_ip_list "$ISP"
done

# Function to apply iptables rules for specific ISP
configure_ports_for_isp() {
    PORT=$1
    ISP_NAME=$2
    echo -e "${YELLOW}Configuring port ${PORT} for ISP ${ISP_NAME}...${ENDCOLOR}"

    if [ ! -f "/etc/iptables/${ISP_NAME}.ipv4" ]; then
        echo -e "${RED}IP list for ${ISP_NAME} not found. Skipping...${ENDCOLOR}"
        return
    fi

    # Apply iptables rules
    while read -r IP; do
        if [ -n "$IP" ]; then
            echo -e "${GREEN}Adding rule for IP: ${IP} on port ${PORT}${ENDCOLOR}"
            iptables -A INPUT -p tcp --dport "$PORT" -s "$IP" -j ACCEPT
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
        iptables -A INPUT -p tcp --dport "$PORT" -j ACCEPT
        echo -e "${GREEN}Port ${PORT} is open for all ISPs.${ENDCOLOR}"
    done
}

# Function to clear all iptables rules
clear_all_config() {
    echo -e "${YELLOW}Clearing all iptables configurations...${ENDCOLOR}"
    iptables -F
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}All iptables rules have been cleared.${ENDCOLOR}"
    else
        echo -e "${RED}Failed to clear iptables rules.${ENDCOLOR}"
    fi
}

# Function to list ISPs and let the user select one
select_isp() {
    echo "Select an ISP:"
    PS3="Enter the number of the ISP: "
    select ISP_NAME in "${ISPS[@]}"; do
        if [[ -n "$ISP_NAME" ]]; then
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
    echo "3) Clear all iptables configurations"
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

# Save iptables rules
save_iptables() {
    echo -e "${YELLOW}Saving iptables rules...${ENDCOLOR}"
    iptables-save > /etc/iptables/rules.v4
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}iptables rules saved successfully.${ENDCOLOR}"
    else
        echo -e "${RED}Failed to save iptables rules.${ENDCOLOR}"
    fi
}

# Enable iptables service if not already running
enable_firewall() {
    echo -e "${YELLOW}Enabling iptables...${ENDCOLOR}"
    systemctl enable iptables
    systemctl start iptables
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}iptables service started successfully.${ENDCOLOR}"
    else
        echo -e "${RED}Failed to start iptables service.${ENDCOLOR}"
    fi
}

# Run the menu
enable_firewall
main_menu
save_iptables
