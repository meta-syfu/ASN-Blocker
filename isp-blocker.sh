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

    echo -e "${YELLOW}Downloading IP list for ${ISP_NAME}...${ENDCOLOR}"
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

# Main menu function
main_menu() {
    clear
    echo "==================== ISP Blocker ===================="
    echo "1) Configure ports for specific ISPs"
    echo "2) Configure always open ports"
    echo "3) Exit"
    echo "====================================================="
    echo -n "Please select an option: "
    read OPTION

    case $OPTION in
        1)
            echo -n "Enter the ports (comma-separated) to configure for specific ISPs: "
            read PORTS
            IFS=',' read -ra PORT_ARRAY <<< "$PORTS"

            for PORT in "${PORT_ARRAY[@]}"; do
                echo -n "For port $PORT, specify the ISP (e.g., mtn, mci): "
                read ISP_NAME

                if [[ " ${ISPS[@]} " =~ " ${ISP_NAME} " ]]; then
                    configure_ports_for_isp "$PORT" "$ISP_NAME"
                else
                    echo -e "${RED}Invalid ISP name: ${ISP_NAME}.${ENDCOLOR}"
                fi
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

# Run the menu
main_menu
save_iptables
