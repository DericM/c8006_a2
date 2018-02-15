#!/bin/sh

source ../config.sh


# Allows firewall access to internet
DEBUG=DROP

function init(){
    echo "Set DNS Server to $DNS_SERVER_IP"
    sudo echo "nameserver $DNS_SERVER_IP" > /etc/resolve.conf

    echo "Activate $PRIVATE_IFACE with ip: $FW_PRIVATE_IP"
    sudo ifconfig $PRIVATE_IFACE $FW_PRIVATE_IP up

    echo "Set ip_forward flag."
    sudo echo "1" >/proc/sys/net/ipv4/ip_forward

    echo "Allow routing from this computer to lab computers"
    sudo route add -net 192.168.0.0 netmask 255.255.255.0 gw $FW_GATEWAY_IP

    echo "Allow routing from local computers to Firewall gateway"
    sudo route add -net $PRIVATE_NETWORK gw $FW_PRIVATE_IP

    $IPT -t nat -A POSTROUTING -j SNAT -s $PRIVATE_NETWORK -o $PUBLIC_IFACE --to-source $FW_PUBLIC_IP
    $IPT -t nat -A PREROUTING -j DNAT -i $PUBLIC_IFACE --to-destination $SVR_PRIVATE_IP

}

function clearIptables(){
    $IPT -P INPUT ACCEPT
    $IPT -P FORWARD ACCEPT
    $IPT -P OUTPUT ACCEPT
    $IPT -F
    $IPT -X
    $IPT -Z
}


function inputChain(){
    $IPT -P INPUT $DEBUG
}


function outputChain(){
    $IPT -P OUTPUT $DEBUG
}



function forwardChain(){
    $IPT -P FORWARD DROP

    #ACCEPT Fragments
    #because reasons.
    $IPT -A FORWARD -f -j ACCEPT

    #DROP packets from outside targeting the private network
    #because people from the outside shouldnt know about it
    echo "DROP packets targeting the private network from outside"
    $IPT -A FORWARD -i $PUBLIC_IFACE -s $PRIVATE_NETWORK -j DROP

    #DROP syn fin packets
    echo "DROP SYN/FIN packets"
    $IPT -A FORWARD -p tcp --tcp-flags SYN,FIN SYN,FIN -j DROP

    #DROP telnet
    $IPT -A FORWARD -p tcp --sport 23 -j DROP
    $IPT -A FORWARD -p tcp --dport 23 -j DROP

    sudo $IPT -A FORWARD -i $PUBLIC_IFACE -o $PRIVATE_IFACE -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    sudo $IPT -A FORWARD -i $PRIVATE_IFACE -o $PUBLIC_IFACE -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

    for port in $TCP_BLOCKED_PORTS
	do
		blockTcpPort $port
    done

    for port in $UDP_BLOCKED_PORTS
	do
		blockUdpPort $port
    done

    for type in $ICMP_BLOCKED_TYPES
	do
		blockIcmpType $type
    done

    for port in $TCP_ALLOWED_PORTS
	do
		openTcpPort $port
    done

    for port in $UDP_ALLOWED_PORTS
	do
		openUdpPort $port
    done

    for type in $ICMP_ALLOWED_TYPES
	do
		allowIcmpType $type
    done

}


function openTcpPort(){
    echo "Open tcp port: $1"
    #$IPT -A FORWARD -p tcp --sport $1 -m state --state NEW,ESTABLISHED -j ACCEPT
    $IPT -A FORWARD -p tcp --dport $1 -m state --state NEW,ESTABLISHED -j ACCEPT
    echo "RESULT: $?"
}

function openUdpPort(){
    echo "Open udp port: $1"
    $IPT -A FORWARD -p udp --dport $1 -m state --state NEW,ESTABLISHED -j ACCEPT
    echo "RESULT: $?"
}

function allowIcmpType(){
    echo "Allow icmp type: $1"
    $IPT -A FORWARD -p icmp --icmp-type $1 -m state --state NEW,ESTABLISHED -j ACCEPT
    echo "RESULT: $?"
}

function blockTcpPort(){
    echo "Block tcp port: $1"
    $IPT -A FORWARD -p tcp --dport $1 -j DROP
    echo "RESULT: $?"
}

function blockUdpPort(){
    echo "Block udp port: $1"
    $IPT -A FORWARD -p udp --dport $1 -j DROP
    echo "RESULT: $?"
}

function blockIcmpType(){
    echo "Block icmp type: $1"
    $IPT -A FORWARD -p icmp --icmp-type $1 -j DROP
    echo "RESULT: $?"
}

function optimizeFTP(){
    echo "Optimizing FTP"
    $IPT -A PREROUTING -t mangle -p tcp --sport ftp -j TOS --set-tos Minimize-Delay
    $IPT -A PREROUTING -t mangle -p tcp --dport ftp -j TOS --set-tos Minimize-Delay
    $IPT -A PREROUTING -t mangle -p tcp --sport ftp-data -j TOS --set-tos Maximize-Throughput
    $IPT -A PREROUTING -t mangle -p tcp --dport ftp-data -j TOS --set-tos Maximize-Throughput
}

function optimizeSSH(){
    echo "Optimizing SSH"
    $IPT -A PREROUTING -t mangle -p tcp --sport ssh -j TOS --set-tos Minimize-Delay
    $IPT -A PREROUTING -t mangle -p tcp --dport ssh -j TOS --set-tos Minimize-Delay
}


clearIptables
init
optimizeFTP
optimizeSSH
inputChain
outputChain
forwardChain
