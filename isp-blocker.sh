#!/bin/bash

ASN_API_KEY="f610de5592msh075dc56033ecc9cp19fc2fjsn25362856a249"
ASN_LOOKUP_URL="https://asn-lookup.p.rapidapi.com/api"

declare -A ASN_LIST=(
    ["MCI"]="AS197207"
    ["AsiaTech"]="AS43754"
    ["MTN"]="AS44244"
    ["MobinNet"]="AS50810"
    ["ParsOnline"]="AS16322"
    ["Pishgaman"]="AS57831"
    ["Rightel"]="AS57218"
    ["Shatel"]="AS31549"
    ["TCI"]="AS58224"
)

# نمایش قوانین iptables فعلی
show_rules() {
    echo "Current iptables rules:"
    iptables -S || echo "Error showing iptables rules"
}

# دریافت رنج IP ها از ASN
fetch_ip_ranges() {
    ASN=$1
    echo "Fetching IP ranges for ASN: $ASN"
    response=$(curl -s -X GET "$ASN_LOOKUP_URL?asn=$ASN" \
        -H "Host: asn-lookup.p.rapidapi.com" \
        -H "X-Rapidapi-Host: asn-lookup.p.rapidapi.com" \
        -H "X-Rapidapi-Key: $ASN_API_KEY")
    
    if [[ $response == *"ipv4_prefix"* ]]; then
        echo "$response" | grep -oP '"ipv4_prefix":\s*\[\K[^\]]+' | tr -d '"' | tr ',' '\n'
    else
        echo "Error fetching IP ranges for ASN: $ASN"
        echo "Response: $response"
    fi
}

# ست کردن iptables برای یک ISP و پورت مشخص
set_iptables_for_isp() {
    ISP=$1
    PORT=$2
    DEFAULT_PORTS=$3

    # دریافت رنج‌های IP برای ISP
    ASN=${ASN_LIST[$ISP]}
    echo "Setting iptables rules for $ISP (ASN: $ASN) on port $PORT"
    IP_RANGES=$(fetch_ip_ranges $ASN)

    # باز کردن پورت برای IPهای خاص و بلاک کردن سایرین
    for IP_RANGE in $IP_RANGES; do
        echo "Allowing $IP_RANGE for port $PORT"
        iptables -A INPUT -p tcp --dport $PORT -s $IP_RANGE -j ACCEPT
    done

    # بلاک کردن همه IP‌های دیگر برای پورت مشخص‌شده
    echo "Blocking all other IPs for port $PORT"
    iptables -A INPUT -p tcp --dport $PORT -j DROP
    
    # باز کردن پورت‌های دیفالت برای همه ISP ها
    for DEFAULT_PORT in ${DEFAULT_PORTS//,/ }; do
        echo "Allowing default port $DEFAULT_PORT for all ISPs"
        iptables -A INPUT -p tcp --dport $DEFAULT_PORT -j ACCEPT
    done

    # باز کردن پورت SSH (22) همیشه
    echo "Allowing SSH (port 22)"
    iptables -A INPUT -p tcp --dport 22 -j ACCEPT
}

# حذف قوانین iptables برای یک ISP
clear_isp_rules() {
    ISP=$1
    PORT=$2

    ASN=${ASN_LIST[$ISP]}
    echo "Clearing rules for $ISP (ASN: $ASN) on port $PORT"
    IP_RANGES=$(fetch_ip_ranges $ASN)

    for IP_RANGE in $IP_RANGES; do
        echo "Removing $IP_RANGE for port $PORT"
        iptables -D INPUT -p tcp --dport $PORT -s $IP_RANGE -j ACCEPT
    done

    iptables -D INPUT -p tcp --dport $PORT -j DROP
}

# ذخیره قوانین iptables بعد از ریبوت
save_iptables_rules() {
    echo "Saving iptables rules"
    iptables-save > /etc/iptables/rules.v4 || echo "Error saving iptables rules"
}

# منوی اصلی
main_menu() {
    while true; do
        clear
        show_rules
        echo "1) Set rules for specific ISP and port"
        echo "2) Set default ports for all ISPs"
        echo "3) Clear all rules"
        echo "4) Exit"
        read -p "Select an option: " OPTION

        case $OPTION in
            1)
                echo "Available ISPs: ${!ASN_LIST[@]}"
                read -p "Enter ISP: " ISP
                read -p "Enter port: " PORT
                read -p "Enter default ports for all ISPs (comma-separated): " DEFAULT_PORTS
                set_iptables_for_isp "$ISP" "$PORT" "$DEFAULT_PORTS"
                save_iptables_rules
                ;;
            2)
                read -p "Enter default ports (comma-separated): " DEFAULT_PORTS
                for ISP in "${!ASN_LIST[@]}"; do
                    set_iptables_for_isp "$ISP" "0" "$DEFAULT_PORTS"
                done
                save_iptables_rules
                ;;
            3)
                iptables -F
                save_iptables_rules
                ;;
            4)
                exit 0
                ;;
            *)
                echo "Invalid option, please try again."
                ;;
        esac
    done
}

main_menu
