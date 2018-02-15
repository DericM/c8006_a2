#!/bin/bash

#
# This function initializes the variables used in the script.
# LAB_* variables represent the external interface and ip associated with the outside network
# LOCAL_* variables are internal interfaces and ips.
#

PUBLIC_IFACE=eno1
PRIVATE_IFACE=enp3s2
SVR_PRIVATE_IP=192.168.10.2
FW_PRIVATE_IP_GATEWAY=192.168.10.1


indent() { sed 's/^/  /'; }

bold=$(tput bold)
normal=$(tput sgr0)

function bold_text() {
    echo "${bold}$1${normal}"
}

function init_client() {
    echo Modifying ${bold}/etc/resolv.conf${normal}
    sudo echo "nameserver 8.8.8.8" > /etc/resolv.conf
    echo "Flushing Routing Rules"
    #ip route del default
    #ip addr flush dev $PRIVATE_IFACE
    echo "Deactivating Lab Interface: $(bold_text $PUBLIC_IFACE)"
    sudo ifconfig $PUBLIC_IFACE down

    echo "Enabling Local Interface: $(bold_text $PRIVATE_IFACE : $SVR_PRIVATE_IP)"
    sudo ifconfig $PRIVATE_IFACE $SVR_PRIVATE_IP up

    echo "Adding Routing Rule for: $(bold_text $FW_PRIVATE_IP_GATEWAY)"
    sudo route add default gw $FW_PRIVATE_IP_GATEWAY
}

function reset_client() {
    echo Enabling Lab Interface: $(bold_text $PUBLIC_IFACE)
    ifconfig $PUBLIC_IFACE up

    echo Disabling Local Interface: $(bold_text $PRIVATE_IFACE)
    ifconfig $PRIVATE_IFACE down
}

function test_client() {
    echo Testing Client
}

if [ $1 = 'init' ]; then
    echo Initializing The Client
    init_client | indent
elif [ $1 = 'reset' ]; then
    echo Resetting Client
    reset_client wat | indent
else
    echo no valid argument passed
fi
