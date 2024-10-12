#!/bin/bash

# نمایش قوانین موجود
echo "Current ufw rules:"
ufw status numbered

# انتخاب نوع عملیات
while true; do
    echo "Select an option:"
    echo "1) Choose ISP and set ports"
    echo "2) Set ports open for all ISPs"
    echo "3) Clear all rules"
    echo "4) Exit"
    read -p "Enter option: " option

    case $option in
        1)
            # انتخاب ISP و تنظیم پورت‌ها
            while true; do
                echo "Select ISP:"
                echo "1) MCI"
                echo "2) MTN"
                echo "3) TCI"
                echo "4) Rightel"
                echo "5) Shatel"
                echo "6) AsiaTech"
                echo "7) Pishgaman"
                echo "8) MobinNet"
                echo "9) ParsOnline"
                echo "b) Back"
                read -p "Enter ISP option: " isp

                case $isp in
                    1)
                        IP_LIST=$(curl -s 'https://raw.githubusercontent.com/meta-syfu/ASN-Blocker/master/mci.ipv4')
                        ISP_NAME="MCI"
                        ;;
                    2)
                        IP_LIST=$(curl -s 'https://raw.githubusercontent.com/meta-syfu/ASN-Blocker/master/mtn.ipv4')
                        ISP_NAME="MTN"
                        ;;
                    3)
                        IP_LIST=$(curl -s 'https://raw.githubusercontent.com/meta-syfu/ASN-Blocker/master/tci.ipv4')
                        ISP_NAME="TCI"
                        ;;
                    4)
                        IP_LIST=$(curl -s 'https://raw.githubusercontent.com/meta-syfu/ASN-Blocker/master/ritel.ipv4')
                        ISP_NAME="Rightel"
                        ;;
                    5)
                        IP_LIST=$(curl -s 'https://raw.githubusercontent.com/meta-syfu/ASN-Blocker/master/shatel.ipv4')
                        ISP_NAME="Shatel"
                        ;;
                    6)
                        IP_LIST=$(curl -s 'https://raw.githubusercontent.com/meta-syfu/ASN-Blocker/master/asiatech.ipv4')
                        ISP_NAME="AsiaTech"
                        ;;
                    7)
                        IP_LIST=$(curl -s 'https://raw.githubusercontent.com/meta-syfu/ASN-Blocker/master/pishgaman.ipv4')
                        ISP_NAME="Pishgaman"
                        ;;
                    8)
                        IP_LIST=$(curl -s 'https://raw.githubusercontent.com/meta-syfu/ASN-Blocker/master/mobinnet.ipv4')
                        ISP_NAME="MobinNet"
                        ;;
                    9)
                        IP_LIST=$(curl -s 'https://raw.githubusercontent.com/meta-syfu/ASN-Blocker/master/parsan.ipv4')
                        ISP_NAME="ParsOnline"
                        ;;
                    b)
                        break
                        ;;
                    *)
                        echo "Invalid option."
                        continue
                        ;;
                esac

                echo "Selected ISP: $ISP_NAME"

                echo "Do you want to:"
                echo "1) Set new ports"
                echo "2) Remove existing rules for this ISP"
                echo "b) Back"
                read -p "Enter your choice: " action

                if [[ "$action" == "1" ]]; then
                    read -p "Enter ports to open (comma-separated, e.g., 30001,80): " ports
                    IFS=',' read -ra PORT_ARRAY <<< "$ports"
                    # Block all ISPs on the specified ports first
                    for port in "${PORT_ARRAY[@]}"; do
                        ufw deny "$port"
                    done
                    # Allow only selected ISP for the ports
                    for port in "${PORT_ARRAY[@]}"; do
                        for ip in $IP_LIST; do
                            ufw allow from "$ip" to any port "$port"
                        done
                    done
                    echo "Ports $ports opened for $ISP_NAME only."
                elif [[ "$action" == "2" ]]; then
                    for port in "${PORT_ARRAY[@]}"; do
                        for ip in $IP_LIST; do
                            ufw delete allow from "$ip" to any port "$port"
                        done
                    done
                    echo "Rules for $ISP_NAME removed."
                elif [[ "$action" == "b" ]]; then
                    continue
                else
                    echo "Invalid option."
                fi
            done
            ;;
        2)
            # باز کردن پورت‌ها برای همه ISP ها
            read -p "Enter ports to open for all ISPs (comma-separated, e.g., 22,2053): " ports
            IFS=',' read -ra PORT_ARRAY <<< "$ports"
            for port in "${PORT_ARRAY[@]}"; do
                ufw allow "$port"
            done
            echo "Ports $ports opened for all ISPs."
            ;;
        3)
            # پاک کردن همه قوانین
            ufw reset
            echo "All ufw rules cleared."
            ;;
        4)
            # خروج
            echo "Exiting."
            break
            ;;
        *)
            echo "Invalid option."
            ;;
    esac
done

# فعال کردن UFW
ufw enable
