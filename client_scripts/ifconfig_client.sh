#!/bin/bash

#
# This function initializes the variables used in the script.
# LAB_* variables represent the external interface and ip associated with the outside network
# LOCAL_* variables are internal interfaces and ips.
#

LAB_INTERFACE_NAME=eno1
LOCAL_INTERFACE_NAME=enp3s2
LOCAL_INTERFACE_IP=192.168.10.2
LOCAL_INTERFACE_GATEWAY_IP=192.168.10.1


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
    #ip addr flush dev $LOCAL_INTERFACE_NAME
    echo "Deactivating Lab Interface: $(bold_text $LAB_INTERFACE_NAME)"
    ifconfig $LAB_INTERFACE_NAME down

    echo "Enabling Local Interface: $(bold_text $LOCAL_INTERFACE_NAME : $LOCAL_INTERFACE_IP)"
    ifconfig $LOCAL_INTERFACE_NAME $LOCAL_INTERFACE_IP up

    echo "Adding Routing Rule for: $(bold_text $LOCAL_INTERFACE_GATEWAY_IP)"
    route add default gw $LOCAL_INTERFACE_GATEWAY_IP
}

function reset_client() {
    echo Enabling Lab Interface: $(bold_text $LAB_INTERFACE_NAME)
    ifconfig $LAB_INTERFACE_NAME up

    echo Disabling Local Interface: $(bold_text $LOCAL_INTERFACE_NAME)
    ifconfig $LOCAL_INTERFACE_NAME down
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
