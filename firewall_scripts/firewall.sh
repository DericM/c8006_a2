
PUBLIC_IFACE=eno1
PUBLIC_NETWORK=192.168.0.0/24

PRIVATE_IFACE=enp3s2
PRIVATE_NETWORK=192.168.10.0/24

FW_PUBLIC_IP=$(ifconfig $PUBLIC_IFACE | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p')

FW_GATEWAY_IP=192.168.0.100


FW_PRIVATE_IP=192.168.10.1

SVR_PRIVATE_IP=192.168.10.2
DNS_SERVER_IP=8.8.8.8


TCP_ALWAYS_BLOCKED_PORTS="32768:32775 137:139 111 515"
UDP_ALWAYS_BLOCKED_PORTS="32768:32775 137:139"
ICMP_ALWAYS_BLOCKED_TYPES=""


TCP_ALLOWED_PORTS="80 8080 22 443 53"
UDP_ALLOWED_PORTS="221 322 53"
ICMP_ALLOWED_TYPES="0 10 11 12 13 14"




#depmod -a
#sudo modprobe ip_tables
#sudo modprobe ip_conntrack
#sudo modprobe ip_conntrack_ftp
#sudo modprobe ip_conntrack_irc
#sudo modprobe iptable_nat
#sudo modprobe ip_nat_ftp
#sudo modprobe ip_nat_irc

#sudo echo 'ip_tables' >> /etc/modules

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

    iptables -t nat -A POSTROUTING -j SNAT -s 192.168.10.0/24 -o $PUBLIC_IFACE --to-source $FW_PUBLIC_IP
    iptables -t nat -A PREROUTING -j DNAT -i $PUBLIC_IFACE --to-destination $SVR_PRIVATE_IP

}

function clearIptables(){
    iptables -P INPUT ACCEPT
    iptables -P FORWARD ACCEPT
    iptables -P OUTPUT ACCEPT
    iptables -t nat -P PREROUTING ACCEPT
    iptables -t nat -P POSTROUTING ACCEPT
    iptables -t nat -P OUTPUT ACCEPT
    iptables -t mangle -P PREROUTING ACCEPT
    iptables -t mangle -P OUTPUT ACCEPT

    iptables -F
    iptables -t nat -F
    iptables -t mangle -F

    iptables -X
    iptables -t nat -X
    iptables -t mangle -X
}



function forwardChain(){
    sudo iptables -P INPUT DROP
    sudo iptables -P OUTPUT DROP
    sudo iptables -P FORWARD DROP

    sudo iptables -A FORWARD -i $PUBLIC_IFACE -o $PRIVATE_IFACE -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    sudo iptables -A FORWARD -i $PRIVATE_IFACE -o $PUBLIC_IFACE -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

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
    echo "Open tcp port: " $1
    sudo iptables -A FORWARD -i $PUBLIC_IFACE -o $PRIVATE_IFACE -p tcp --syn --dport $1 -m conntrack --ctstate NEW -j ACCEPT
    sudo iptables -t nat -A PREROUTING -i $PUBLIC_IFACE -p tcp --dport $1 -j DNAT --to-destination $SVR_PRIVATE_IP
    sudo iptables -t nat -A POSTROUTING -o $PRIVATE_IFACE -p tcp --dport $1 -d $SVR_PRIVATE_IP -j SNAT --to-source $FW_PRIVATE_IP
}

function openUdpPort(){
    echo "Open udp port: " $1
    #sudo iptables -A FORWARD -i $PUBLIC_IFACE -o $PRIVATE_IFACE -p udp --syn --dport $1 -m conntrack --ctstate NEW -j ACCEPT
    sudo iptables -t nat -A PREROUTING -i $PUBLIC_IFACE -p udp --dport $1 -j DNAT --to-destination $SVR_PRIVATE_IP
    sudo iptables -t nat -A POSTROUTING -o $PRIVATE_IFACE -p udp --dport $1 -d $SVR_PRIVATE_IP -j SNAT --to-source $FW_PRIVATE_IP
}

function allowIcmpType(){
    echo "Allow icmp type: " $1
    #sudo iptables -A FORWARD -i $PUBLIC_IFACE -o $PRIVATE_IFACE -p icmp --syn --icmp-type $1 -m conntrack --ctstate NEW -j ACCEPT
    sudo iptables -t nat -A PREROUTING -i $PUBLIC_IFACE -p icmp --icmp-type $1 -j DNAT --to-destination $SVR_PRIVATE_IP
    sudo iptables -t nat -A POSTROUTING -o $PRIVATE_IFACE -p icmp --icmp-type $1 -d $SVR_PRIVATE_IP -j SNAT --to-source $FW_PRIVATE_IP
}


#sudo iptables -A FORWARD -i $PUBLIC_IFACE -o $PRIVATE_IFACE -p tcp --syn --dport 80 -m conntrack --ctstate NEW -j ACCEPT
#sudo iptables -t nat -A PREROUTING -i $PUBLIC_IFACE -p tcp --dport 80 -j DNAT --to-destination $SVR_PRIVATE_IP
#sudo iptables -t nat -A POSTROUTING -o $PRIVATE_IFACE -p tcp --dport 80 -d $SVR_PRIVATE_IP -j SNAT --to-source $FW_PRIVATE_IP


clearIptables
init
forwardChain
