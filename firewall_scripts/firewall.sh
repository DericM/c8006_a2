
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
ICMP_BLOCKED_TYPES=""

TCP_ALLOWED_PORTS="80 8080 22 443 53"
UDP_ALLOWED_PORTS="221 322 53"
ICMP_ALLOWED_TYPES="0 10 11 12 13 14"

IPT=iptables

function init(){

    #ip addr flush dev $PUBLIC_IFACE
    #ip addr flush dev $LOCAL_INTERFACE_NAME
    echo "Set DNS Server to $DNS_SERVER_IP"
    sudo echo "nameserver $DNS_SERVER_IP" > /etc/resolve.conf

    echo "Activate $PRIVATE_IFACE with ip: $FW_PRIVATE_IP"
    sudo ifconfig $PRIVATE_IFACE $FW_PRIVATE_IP up

    echo "Set ip_forward flag."
    sudo echo "1" >/proc/sys/net/ipv4/ip_forward

    #ip route flush table main
    #route add default gw 192.168.0.100

    echo "Allow routing from this computer to lab computers"
    sudo route add -net 192.168.0.0 netmask 255.255.255.0 gw $FW_GATEWAY_IP

    echo "Allow routing from local computers to Firewall gateway"
    sudo route add -net 192.168.10.0/24 gw $FW_PRIVATE_IP

    $IPT -t nat -A POSTROUTING -j SNAT -s 192.168.10.0/24 -o $PUBLIC_IFACE --to-source $FW_PUBLIC_IP
    $IPT -t nat -A PREROUTING -j DNAT -i $PUBLIC_IFACE --to-destination $SVR_PRIVATE_IP

}

function clear$IPT(){
    $IPT -P INPUT ACCEPT
    $IPT -P FORWARD ACCEPT
    $IPT -P OUTPUT ACCEPT
    $IPT -t nat -P PREROUTING ACCEPT
    $IPT -t nat -P POSTROUTING ACCEPT
    $IPT -t nat -P OUTPUT ACCEPT
    $IPT -t mangle -P PREROUTING ACCEPT
    $IPT -t mangle -P OUTPUT ACCEPT

    $IPT -F
    $IPT -t nat -F
    $IPT -t mangle -F

    $IPT -X
    $IPT -t nat -X
    $IPT -t mangle -X
}


function inputChain(){
    sudo $IPT -P INPUT ACCEPT
}


function outputChain(){
    sudo $IPT -P OUTPUT ACCEPT
}



function forwardChain(){
    sudo $IPT -P FORWARD DROP

    #ACCEPT Fragments
    #because reasons.
    $IPT -A FORWARD -f -j ACCEPT

    #DROP packets from outside targeting the private network
    #because people from the outside shouldnt know about it
    $IPT -A FORWARD -p all -d $PRIVATE_NETWORK -j DROP

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

    for type in $ICMP_BLOCKED_PORTS
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
    #sudo $IPT -A FORWARD -i $PUBLIC_IFACE -o $PRIVATE_IFACE -p tcp --syn --dport $1 -m conntrack --ctstate NEW -j ACCEPT
    #sudo $IPT -A FORWARD -p tcp --dport $1 -j ACCEPT

    $IPT -A FORWARD -p tcp --sport $1 -m state --state NEW,ESTABLISHED -j ACCEPT
    $IPT -A FORWARD -p tcp --dport $1 -m state --state NEW,ESTABLISHED -j ACCEPT


    echo "RESULT: $?"
    #sudo $IPT -t nat -A PREROUTING -i $PUBLIC_IFACE -p tcp --dport $1 -j DNAT --to-destination $SVR_PRIVATE_IP
    #sudo $IPT -t nat -A POSTROUTING -o $PRIVATE_IFACE -p tcp --dport $1 -d $SVR_PRIVATE_IP -j SNAT --to-source $FW_PRIVATE_IP
}

function openUdpPort(){
    echo "Open udp port: $1"
    sudo $IPT -A FORWARD -p udp --dport $1 -j ACCEPT
    echo "RESULT: $?"
    #sudo $IPT -A FORWARD -i $PUBLIC_IFACE -o $PRIVATE_IFACE -p udp --syn --dport $1 -m conntrack --ctstate NEW -j ACCEPT
    #sudo $IPT -t nat -A PREROUTING -i $PUBLIC_IFACE -p udp --dport $1 -j DNAT --to-destination $SVR_PRIVATE_IP
    #sudo $IPT -t nat -A POSTROUTING -o $PRIVATE_IFACE -p udp --dport $1 -d $SVR_PRIVATE_IP -j SNAT --to-source $FW_PRIVATE_IP
}

function allowIcmpType(){
    echo "Allow icmp type: $1"
    sudo $IPT -A FORWARD -p icmp --icmp-type $1 -j ACCEPT
    echo "RESULT: $?"
    #sudo $IPT -A FORWARD -i $PUBLIC_IFACE -o $PRIVATE_IFACE -p icmp --syn --icmp-type $1 -m conntrack --ctstate NEW -j ACCEPT
    #sudo $IPT -t nat -A PREROUTING -i $PUBLIC_IFACE -p icmp --icmp-type $1 -j DNAT --to-destination $SVR_PRIVATE_IP
    #sudo $IPT -t nat -A POSTROUTING -o $PRIVATE_IFACE -p icmp --icmp-type $1 -d $SVR_PRIVATE_IP -j SNAT --to-source $FW_PRIVATE_IP
}

function blockTcpPort(){
    echo "Block tcp port: $1"
    sudo $IPT -A FORWARD -p tcp --dport $1 -j DROP
    echo "RESULT: $?"
}

function blockUdpPort(){
    echo "Block udp port: $1"
    sudo $IPT -A FORWARD -p udp --dport $1 -j DROP
    echo "RESULT: $?"
}

function blockIcmpType(){
    echo "Block icmp type: $1"
    sudo $IPT -A FORWARD -p icmp --icmp-type $1 -j DROP
    echo "RESULT: $?"
}


function dropIPSpoofingPackets(){
    sudo $IPT -A FORWARD -p tcp --dport $1 -j DROP
    echo "RESULT: $?"
}

#sudo $IPT -A FORWARD -i $PUBLIC_IFACE -o $PRIVATE_IFACE -p tcp --syn --dport 80 -m conntrack --ctstate NEW -j ACCEPT
#sudo $IPT -t nat -A PREROUTING -i $PUBLIC_IFACE -p tcp --dport 80 -j DNAT --to-destination $SVR_PRIVATE_IP
#sudo $IPT -t nat -A POSTROUTING -o $PRIVATE_IFACE -p tcp --dport 80 -d $SVR_PRIVATE_IP -j SNAT --to-source $FW_PRIVATE_IP


clear$IPT
init
inputChain
outputChain
forwardChain
