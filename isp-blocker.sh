#!/bin/bash

# Color setup for text
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ASN lookup API Key
API_KEY="f610de5592msh075dc56033ecc9cp19fc2fjsn25362856a249"
ASN_LOOKUP_URL="https://asn-lookup.p.rapidapi.com/api"

# Function to fetch IP ranges from ASN
fetch_ip_ranges() {
    ASN=$1
    echo -e "${YELLOW}Fetching IP ranges for ASN: $ASN...${NC}"
    
    # Call ASN API to get IP ranges
    response=$(curl -s -X GET "$ASN_LOOKUP_URL?asn=$ASN" \
        -H "Host: asn-lookup.p.rapidapi.com" \
        -H "X-Rapidapi-Host: asn-lookup.p.rapidapi.com" \
        -H "X-Rapidapi-Key: $API_KEY")

    # Extract IP ranges from the response
    if [[ $response == *"ipv4_prefix"* ]]; then
        ip_ranges=$(echo "$response" | grep -oP '"ipv4_prefix":\s*\[\K[^\]]+' | tr -d '"' | tr ',' '\n')
        echo "$ip_ranges"
    else
        echo -e "${RED}Error fetching IP ranges for ASN: $ASN${NC}"
        echo -e "${RED}Response: $response${NC}"
        return 1
    fi
}

# Function to apply iptables rules for a specific ISP
apply_isp_rules() {
    ISP=$1
    PORT=$2

    # Map ISP to ASN
    case $ISP in
        1) ASN="AS197207" ;;  # MCI
        2) ASN="AS43754" ;;   # AsiaTech
        3) ASN="AS44244" ;;   # MTN Irancell
        4) ASN="AS50810" ;;   # MobinNet
        5) ASN="AS16322" ;;   # ParsOnline
        6) ASN="AS34918" ;;   # Pishgaman
        7) ASN="AS57218" ;;   # Rightel
        8) ASN="AS31549" ;;   # Shatel
        9) ASN="AS58224" ;;   # TCI
        *) echo -e "${RED}Invalid ISP selection!${NC}"; return ;;
    esac

    # Fetch the IP ranges for the selected ASN
    IP_LIST=$(fetch_ip_ranges $ASN)

    # If no IPs are returned, exit early
    if [[ $? -ne 0 || -z "$IP_LIST" ]]; then
        echo -e "${RED}No IP ranges found for ASN: $ASN${NC}"
        return 1
    fi

    echo -e "${GREEN}Applying rules for ISP $ISP on port $PORT...${NC}"

    # Apply iptables rules to allow traffic from the ISP's IP ranges on the specified port
    for IP in $IP_LIST; do
        iptables -A INPUT -p tcp -s $IP --dport $PORT -j ACCEPT
        echo -e "${CYAN}Allowed traffic from $IP on port $PORT${NC}"
    done

    # Block all other connections on the specified port
    iptables -A INPUT -p tcp --dport $PORT -j DROP

    echo -e "${GREEN}Rules applied successfully for $ISP on port $PORT!${NC}"
}

# Set default ports for all ISPs
set_default_ports() {
    PORTS=($1)
    for PORT in "${PORTS[@]}"; do
        iptables -A INPUT -p tcp --dport $PORT -j ACCEPT
        echo -e "${CYAN}Opened port $PORT for all ISPs${NC}"
    done
    echo -e "${GREEN}Default ports $1 are now open for all ISPs!${NC}"
}

# Clear all iptables rules
clear_rules() {
    iptables -F
    echo -e "${RED}All rules have been cleared!${NC}"
}

# Main menu
while true; do
    echo -e "${CYAN}1) Set rules for specific ISP and port${NC}"
    echo -e "${CYAN}2) Set default ports for all ISPs${NC}"
    echo -e "${CYAN}3) Clear all rules${NC}"
    echo -e "${CYAN}4) Exit${NC}"
    read -p "Select an option: " OPTION

    case $OPTION in
        1)
            echo -e "${CYAN}Available ISPs:${NC}"
            echo -e "${CYAN}1) MCI${NC}"
            echo -e "${CYAN}2) AsiaTech${NC}"
            echo -e "${CYAN}3) MTN Irancell${NC}"
            echo -e "${CYAN}4) MobinNet${NC}"
            echo -e "${CYAN}5) ParsOnline${NC}"
            echo -e "${CYAN}6) Pishgaman${NC}"
            echo -e "${CYAN}7) Rightel${NC}"
            echo -e "${CYAN}8) Shatel${NC}"
            echo -e "${CYAN}9) TCI${NC}"
            echo -e "${CYAN}0) Back${NC}"
            read -p "Enter ISP number: " ISP
            [ "$ISP" -eq 0 ] && continue
            read -p "Enter port: " PORT
            apply_isp_rules $ISP $PORT
            ;;
        2)
            read -p "Enter default ports (comma-separated, e.g. 22,2053): " DEFAULT_PORTS
            set_default_ports $(echo $DEFAULT_PORTS | tr ',' ' ')
            ;;
        3)
            clear_rules
            ;;
        4)
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option, please try again!${NC}"
            ;;
    esac
done
