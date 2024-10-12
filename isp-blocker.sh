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

function Figlet
{
    if ! command -v figlet &> /dev/null; then
        sudo apt update && sudo apt install -y figlet
    fi
}

function Iptable
{
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
    figlet "YourScript" 

    echo -e "${C_WHITE}Which ISP do you want block/unblock?"
    echo ""

    echo -e "${C_DARKSLATEGRAY3}1 - Hamrah Aval"
    echo -e "${C_YELLOW}2 - Irancell"
    echo -e "${C_PALETURQUOISE1}3 - Mokhaberat"
    echo -e "${C_SKYBLUE2}4 - Rightel"
    echo -e "${C_LIGHTSALMON1}5 - Shatel"
    echo -e "${C_THISTLE1}6 - AsiaTech"
    echo -e "${C_INDIANRED1}7 - Pishgaman"
    echo -e "${C_SPRINGGREEN2}8 - MobinNet"
    echo -e "${C_DARKORANGE}9 - ParsOnline"
    echo -e "${C_MAGENTA2}10 - Exit"

    echo -e "${C_WHITE}"

    read -p "Enter your choice : " isp
    case $isp in
        1) isp="MCI" blocking_menu ;;
        2) isp="MTN" blocking_menu ;;
        3) isp="TCI" blocking_menu ;;
        4) isp="Rightel" blocking_menu ;;
        5) isp="Shatel" blocking_menu ;;
        6) isp="AsiaTech" blocking_menu ;;
        7) isp="Pishgaman" blocking_menu ;;
        8) isp="MobinNet" blocking_menu ;;
        9) isp="ParsOnline" blocking_menu ;;
        10) echo -e "${C_RED1}"; clear; figlet "BYE"; exit 0 ;;
        *) 
        echo -e "${C_RED1}Invalid option!"; main_menu ;;
    esac
}

function blocking_menu {
    clear

    Figlet
    echo -e "${C_CHARTREUSE1}"
    figlet "YourScript" 
    
    echo ""
    echo -e "${C_LIGHTSALMON1}1 - Block $isp"
    echo -e "${C_MAGENTA2}2 - UnBlock All"
    echo -e "${C_PALETURQUOISE1}3 - Back to Main Menu"

    echo -e "${C_WHITE}"

    read -p "Enter your choice : " choice
    echo ""
    
    case $choice in
        1) blocker ;;
        2) unblocker ;;
        3) main_menu ;;
        *) 
        echo -e "${C_RED1}Invalid option press enter!"; blocking_menu ;;
    esac
}

function blocker {
    clear
    Figlet
    Iptable

    if ! iptables -L isp-blocker -n >/dev/null 2>&1; then
        iptables -N isp-blocker
    fi

    if ! iptables -C INPUT -j isp-blocker &> /dev/null; then
        iptables -I INPUT -j isp-blocker
    fi

    clear
    echo -e "${C_CHARTREUSE1}"
    figlet "YourScript" 

    echo -e "${C_WHITE}"
    read -p "Are you sure about blocking $isp ? [Y/N] : " confirm
    
    if [[ $confirm == [Yy]* ]]; then
        clear
        case $isp in
        "MCI")
            IP_LIST=$(curl -s 'https://raw.githubusercontent.com/meta-syfu/ASN-Blocker/master/mci.ipv4')
            ;;
        "MTN")
            IP_LIST=$(curl -s 'https://raw.githubusercontent.com/meta-syfu/ASN-Blocker/master/mtn.ipv4')
            ;;
        "TCI")
            IP_LIST=$(curl -s 'https://raw.githubusercontent.com/meta-syfu/ASN-Blocker/master/tci.ipv4')
            ;;
        "Rightel")
            IP_LIST=$(curl -s 'https://raw.githubusercontent.com/meta-syfu/ASN-Blocker/master/ritel.ipv4')
            ;;
        "Shatel")
            IP_LIST=$(curl -s 'https://raw.githubusercontent.com/meta-syfu/ASN-Blocker/master/shatel.ipv4')
            ;;
        "AsiaTech")
            IP_LIST=$(curl -s 'https://raw.githubusercontent.com/meta-syfu/ASN-Blocker/master/asiatech.ipv4')
            ;;
        "Pishgaman")
            IP_LIST=$(curl -s 'https://raw.githubusercontent.com/meta-syfu/ASN-Blocker/master/pishgaman.ipv4')
            ;;
        "MobinNet")
            IP_LIST=$(curl -s 'https://raw.githubusercontent.com/meta-syfu/ASN-Blocker/master/mobinnet.ipv4')
            ;;
        "ParsOnline")
            IP_LIST=$(curl -s 'https://raw.githubusercontent.com/meta-syfu/ASN-Blocker/master/parsan.ipv4')
            ;;
        esac

        if [ $? -ne 0 ]; then
            echo -e "${C_WHITE}"
            echo -e "${C_RED1}Failed to fetch the IP list."
            read -p "Press enter to return to Menu!" dummy
        
            blocking_menu
        fi
        
        # Continue blocking code...
    else
        echo -e "${C_RED1}Cancelled!"
        echo ""
        read -p "Press enter to return to Menu" dummy
        blocking_menu
    fi
}

function unblocker {
    clear
    iptables -F isp-blocker
    iptables-save > /etc/iptables/rules.v4
    
    clear
    echo -e "${C_CHARTREUSE1}"
    figlet "YourScript" 

    echo -e "${C_CHARTREUSE1}All ISPs UnBlocked successfully!"
    read -p "Press enter to return to Menu" dummy
    blocking_menu
}

main_menu
