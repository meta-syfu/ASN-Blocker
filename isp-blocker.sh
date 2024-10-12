#!/bin/bash

ASN_LOOKUP_URL="https://asn-lookup.p.rapidapi.com/api"
ASN_API_KEY="f610de5592msh075dc56033ecc9cp19fc2fjsn25362856a249"

# دریافت رنج IP ها از ASN
fetch_ip_ranges() {
    ASN=$1
    echo "Fetching IP ranges for ASN: $ASN"
    response=$(curl -s -X GET "$ASN_LOOKUP_URL?asn=$ASN" \
        -H "Host: asn-lookup.p.rapidapi.com" \
        -H "X-Rapidapi-Host: asn-lookup.p.rapidapi.com" \
        -H "X-Rapidapi-Key: $ASN_API_KEY")
    
    if [[ $response == *"ipv4_prefix"* ]]; then
        echo "$response" | jq -r '.ipv4_prefix[]'
    else
        echo "No IP ranges found for ASN: $ASN"
    fi

    if [[ $response == *"ipv6_prefix"* ]]; then
        echo "$response" | jq -r '.ipv6_prefix[]'
    else
        echo "No IPv6 ranges found for ASN: $ASN"
    fi
}

# اعمال قوانین iptables برای یک ISP و پورت مشخص
apply_rules() {
    ISP=$1
    PORT=$2
    echo "Applying rules for ISP $ISP on port $PORT..."

    IP_RANGES=$(fetch_ip_ranges $ISP)
    if [[ -n "$IP_RANGES" ]]; then
        for IP in $IP_RANGES; do
            iptables -A INPUT -p tcp --dport $PORT -s $IP -j ACCEPT
            echo "Allowed IPv4 traffic from $IP on port $PORT"
        done
    fi

    # برای IPv6 هم قوانین را اعمال کنیم
    IP6_RANGES=$(fetch_ip_ranges $ISP | grep ':')

    if [[ -n "$IP6_RANGES" ]]; then
        for IP6 in $IP6_RANGES; do
            ip6tables -A INPUT -p tcp --dport $PORT -s $IP6 -j ACCEPT
            echo "Allowed IPv6 traffic from $IP6 on port $PORT"
        done
    fi
    echo "Rules applied successfully for ISP $ISP on port $PORT!"
}

# نمایش قوانین فعال
view_active_rules() {
    echo "Active IPv4 Rules:"
    iptables -L
    echo "Active IPv6 Rules:"
    ip6tables -L
}

# نمایش لاگ‌ها
view_logs() {
    echo "Showing iptables logs:"
    tail -n 50 /var/log/syslog | grep 'iptables'
}

# منو اصلی
while true; do
    echo "1) Set rules for specific ISP and port"
    echo "2) View active rules"
    echo "3) View logs"
    echo "4) Exit"
    read -p "Select an option: " option
    case $option in
        1)
            echo "Available ISPs:"
            echo "1) MCI"
            echo "2) AsiaTech"
            echo "3) MTN Irancell"
            echo "4) MobinNet"
            echo "5) ParsOnline"
            echo "6) Pishgaman"
            echo "7) Rightel"
            echo "8) Shatel"
            echo "9) TCI"
            echo "0) Back"
            read -p "Enter ISP number: " isp
            read -p "Enter port: " port
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
            echo "Invalid option"
            ;;
    esac
done
