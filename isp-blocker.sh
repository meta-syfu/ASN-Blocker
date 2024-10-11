#!/bin/bash

C_CHARTREUSE1="\033[38;5;118m"
C_SPRINGGREEN2="\033[38;5;42m"
C_INDIANRED1="\033[38;5;204m"
C_SKYBLUE2="\033[38;5;111m"
C_THISTLE1="\033[38;5;225m"
C_LIGHTSALMON1="\033[38;5;216m"
C_PALETURQUOISE1="\033[38;5;159m"
C_YELLOW="\033[38;5;11m"
C_DARKSLATEGRAY3="\033[38;5;116m"
C_RED1="\033[38;5;196m"
C_MAGENTA2="\033[38;5;200m"
C_WHITE="\033[38;5;15m"
C_DARKORANGE="\033[38;5;208m"

if [[ $EUID -ne 0 ]]; then
    clear
    echo -e "${C_RED1}You should run this script with root!"
    echo -e "${C_RED1}Use sudo -i to change user to root!"
    exit 1
fi

function Figlet {
    if ! command -v figlet &> /dev/null; then
        sudo apt update && sudo apt install -y figlet
    fi
}

function Iptable {
    if ! command -v iptables &> /dev/null; then
        apt-get update
        apt-get install -y iptables
    fi

    if ! dpkg -s iptables-persistent &> /dev/null; then
        apt-get update
        apt-get install -y iptables-persistent
    fi
}

function main_menu {
    clear
    Figlet
    echo -e "${C_CHARTREUSE1}"
    figlet "Ch4mr00sh"

    echo -e "${C_WHITE}Which ports do you want to configure?"
    read -p "Enter ports (e.g., 22343, 22, 2053): " ports
    echo -e "${C_WHITE}Select ISP to allow for these ports:"

    echo -e "${C_DARKSLATEGRAY3}1 - Hamrah Aval"
    echo -e "${C_YELLOW}2 - Irancell"
    echo -e "${C_PALETURQUOISE1}3 - Mokhaberat"
    echo -e "${C_SKYBLUE2}4 - Rightel"
    echo -e "${C_LIGHTSALMON1}5 - Shatel"
    echo -e "${C_THISTLE1}6 - AsiaTech"
    echo -e "${C_INDIANRED1}7 - Pishgaman"
    echo -e "${C_SPRINGGREEN2}8 - MobinNet"
    echo -e "${C_DARKORANGE}9 - ParsOnline"
    echo -e "${C_MAGENTA2}10 - All ISPs (block all except whitelisted)"

    echo -e "${C_WHITE}"

    read -p "Enter your choice : " isp_choice
    case $isp_choice in
        1) isp="MCI" ;;
        2) isp="MTN" ;;
        3) isp="TCI" ;;
        4) isp="Rightel" ;;
        5) isp="Shatel" ;;
        6) isp="AsiaTech" ;;
        7) isp="Pishgaman" ;;
        8) isp="MobinNet" ;;
        9) isp="ParsOnline" ;;
        10) isp="ALL" ;;
        *) 
        echo -e "${C_RED1}Invalid option!"; main_menu ;;
    esac

    configure_ports $isp $ports
}

function configure_ports {
    isp=$1
    ports=$2
    clear
    Figlet
    echo -e "${C_CHARTREUSE1}"
    figlet "Ch4mr00sh"

    echo -e "${C_WHITE}Configuring ports [$ports] for ISP [$isp]"

    # Fetch the IP list for the selected ISP
    case $isp in
        "MCI")
            IP_LIST=$(curl -s 'https://raw.githubusercontent.com/meta-syfu/IR-ISP-Blocker/master/mci.ipv4')
            ;;
        "MTN")
            IP_LIST=$(curl -s 'https://raw.githubusercontent.com/meta-syfu/IR-ISP-Blocker/master/mtn.ipv4')
            ;;
        "TCI")
            IP_LIST=$(curl -s 'https://raw.githubusercontent.com/meta-syfu/IR-ISP-Blocker/master/tci.ipv4')
            ;;
        "Rightel")
            IP_LIST=$(curl -s 'https://raw.githubusercontent.com/meta-syfu/IR-ISP-Blocker/master/ritel.ipv4')
            ;;
        "Shatel")
            IP_LIST=$(curl -s 'https://raw.githubusercontent.com/meta-syfu/IR-ISP-Blocker/master/shatel.ipv4')
            ;;
        "AsiaTech")
            IP_LIST=$(curl -s 'https://raw.githubusercontent.com/meta-syfu/IR-ISP-Blocker/master/asiatech.ipv4')
            ;;
        "Pishgaman")
            IP_LIST=$(curl -s 'https://raw.githubusercontent.com/meta-syfu/IR-ISP-Blocker/master/pishgaman.ipv4')
            ;;
        "MobinNet")
            IP_LIST=$(curl -s 'https://raw.githubusercontent.com/meta-syfu/IR-ISP-Blocker/master/mobinnet.ipv4')
            ;;
        "ParsOnline")
            IP_LIST=$(curl -s 'https://raw.githubusercontent.com/meta-syfu/IR-ISP-Blocker/master/parsan.ipv4')
            ;;
        "ALL")
            IP_LIST=$(curl -s 'https://raw.githubusercontent.com/meta-syfu/IR-ISP-Blocker/master/all.ipv4')
            ;;
    esac

    # Apply IPTABLES rules to block other ISPs and allow selected ISP
    IFS=',' read -r -a portArray <<< "$ports"
    for port in "${portArray[@]}"; do
        for IP in $IP_LIST; do
            iptables -A INPUT -p tcp --dport $port -s $IP -j ACCEPT
        done
        iptables -A INPUT -p tcp --dport $port -j DROP
    done

    iptables-save > /etc/iptables/rules.v4
    echo -e "${C_YELLOW}Ports [$ports] configured for ISP [$isp]."
    read -p "Press enter to return to the menu..." dummy
    main_menu
}

main_menu
