#!/bin/bash
IPT=iptables

PUBLIC_IFACE=eno1
PUBLIC_NETWORK=192.168.0.0/24

PRIVATE_IFACE=enp3s2
PRIVATE_NETWORK=192.168.10.0/24

FW_PUBLIC_IP=$(ifconfig $PUBLIC_IFACE | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p')
FW_GATEWAY_IP=192.168.0.100
FW_PRIVATE_IP=192.168.10.1

SVR_PRIVATE_IP=192.168.10.2
DNS_SERVER_IP=8.8.8.8


TCP_BLOCKED_PORTS="32768 32769 32770 32771 32772 32773 32774 32775 137 138 139 111 515"
UDP_BLOCKED_PORTS="32768 32769 32770 32771 32772 32773 32774 32775 137 138 139"
ICMP_BLOCKED_TYPES="0"

TCP_ALLOWED_PORTS="80 8080 20 21 22 443 53"
UDP_ALLOWED_PORTS="221 322 53"
ICMP_ALLOWED_TYPES="8 13"

# Formatting
indent() { sed 's/^/  /'; }

RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
bold=$(tput bold)
normal=$(tput sgr0)

function bt() {
    echo "${bold}$1${normal}"
}

function rt() {
    echo "${RED}$1${normal}"
}

function gt() {
    echo "${GREEN}$1${normal}"
}
