#!/bin/bash

# رنگ بندی
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

ASN_LOOKUP_URL="https://asn-lookup.p.rapidapi.com/api"
ASN_API_KEY="f610de5592msh075dc56033ecc9cp19fc2fjsn25362856a249"

# تابع برای دریافت IPهای ASN
fetch_ip_ranges() {
    ASN=$1
    echo -e "${BLUE}Fetching IP ranges for ASN: $ASN${NC}"
    response=$(curl -s -X GET "$ASN_LOOKUP_URL?asn=$ASN" \
        -H "Host: asn-lookup.p.rapidapi.com" \
        -H "X-Rapidapi-Host: asn-lookup.p.rapidapi.com" \
        -H "X-Rapidapi-Key: $ASN_API_KEY")
    
    if [[ $response == *"ipv4_prefix"* ]]; then
        echo "$response" | jq -r '.ipv4_prefix[]'
    else
        echo -e "${RED}No IPv4 ranges found for ASN: $ASN${NC}"
    fi

    if [[ $response == *"ipv6_prefix"* ]]; then
        echo "$response" | jq -r '.ipv6_prefix[]'
    else
        echo -e "${RED}No IPv6 ranges found for ASN: $ASN${NC}"
    fi
}

# تابع برای اعمال قوانین
apply_rules() {
    ISP=$1
    PORT=$2
    echo -e "${GREEN}Applying rules for ISP $ISP on port $PORT...${NC}"

    IP_RANGES=$(fetch_ip_ranges $ISP)
    if [[ -n "$IP_RANGES" ]]; then
        for IP in $IP_RANGES; do
            iptables -A INPUT -p tcp --dport $PORT -s $IP -j ACCEPT
            echo -e "${YELLOW}Allowed IPv4 traffic from $IP on port $PORT${NC}"
        done
    fi

    # اعمال قوانین IPv6
    IP6_RANGES=$(fetch_ip_ranges $ISP | grep ':')

    if [[ -n "$IP6_RANGES" ]]; then
        for IP6 in $IP6_RANGES; do
            ip6tables -A INPUT -p tcp --dport $PORT -s $IP6 -j ACCEPT
            echo -e "${YELLOW}Allowed IPv6 traffic from $IP6 on port $PORT${NC}"
        done
    fi
    echo -e "${GREEN}Rules applied successfully for ISP $ISP on port $PORT!${NC}"
}

# نمایش قوانین فعال
view_active_rules() {
    echo -e "${BLUE}Active IPv4 Rules:${NC}"
    iptables -L
    echo -e "${BLUE}Active IPv6 Rules:${NC}"
    ip6tables -L
}

# نمایش لاگ‌ها
view_logs() {
    echo -e "${BLUE}Showing iptables logs:${NC}"
    tail -n 50 /var/log/syslog | grep 'iptables'
}

# منو اصلی
while true; do
    echo -e "${BLUE}1) Set rules for specific ISP and port${NC}"
    echo -e "${BLUE}2) View active rules${NC}"
    echo -e "${BLUE}3) View logs${NC}"
    echo -e "${BLUE}4) Exit${NC}"
    read -p "Select an option: " option
    case $option in
        1)
            echo -e "${BLUE}Available ISPs:${NC}"
            echo -e "${BLUE}1) MCI${NC}"
            echo -e "${BLUE}2) AsiaTech${NC}"
            echo -e "${BLUE}3) MTN Irancell${NC}"
            echo -e "${BLUE}4) MobinNet${NC}"
            echo -e "${BLUE}5) ParsOnline${NC}"
            echo -e "${BLUE}6) Pishgaman${NC}"
            echo -e "${BLUE}7) Rightel${NC}"
            echo -e "${BLUE}8) Shatel${NC}"
            echo -e "${BLUE}9) TCI${NC}"
            echo -e "${BLUE}0) Back${NC}"
            read -p "Enter ISP number: " isp
            read -p "Enter port: " port
            # باز نگه داشتن پورت 22
            iptables -A INPUT -p tcp --dport 22 -j ACCEPT
            ip6tables -A INPUT -p tcp --dport 22 -j ACCEPT
            apply_rules $isp $port
            ;;
        2)
            view_active_rules
            ;;
        3)
            view_logs
            ;;
        4)
            break
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            ;;
    esac
done
