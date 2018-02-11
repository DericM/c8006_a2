
LAB_INTERFACE_NAME=eno1
LAB_INTERFACE_IP=$(ifconfig $LAB_INTERFACE_NAME | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p')

LOCAL_INTERFACE_NAME=enp3s2
LOCAL_INTERFACE_IP=192.168.10.1

CLIENT_IP=192.168.10.2

DNS_SERVER=8.8.8.8



TCP_ALLOWED_PORTS="80 8080 22 443"
UDP_ALLOWED_PORTS="221 322"
ICMP_ALLOWED_TYPES="0 13 14"

TCP_ALWAYS_BLOCKED_PORTS="32768:32775 137:139 111 515"
UDP_ALWAYS_BLOCKED_PORTS="32768:32775 137:139"
ICMP_ALWAYS_BLOCKED_TYPES=""


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
    
    #ip addr flush dev $LAB_INTERFACE_NAME
    #ip addr flush dev $LOCAL_INTERFACE_NAME
    echo "Set DNS Server to $DNS_SERVER"
    sudo echo "nameserver $DNS_SERVER" > /etc/resolve.conf

    echo "Activate $LOCAL_INTERFACE_NAME with ip: $LOCAL_INTERFACE_IP"
    sudo ifconfig $LOCAL_INTERFACE_NAME $LOCAL_INTERFACE_IP up

    echo "Set ip_forward flag."
    sudo echo "1" >/proc/sys/net/ipv4/ip_forward

    #ip route flush table main
    #route add default gw 192.168.0.100

    echo "Allow routing from this computer to lab computers"
    sudo route add -net 192.168.0.0 netmask 255.255.255.0 gw $LAB_INTERFACE_IP

    echo "Allow routing from local computers to Firewall gateway"
    sudo route add -net 192.168.10.0/24 gw $LOCAL_INTERFACE_IP
    
    iptables -t nat -A POSTROUTING -j SNAT -s 192.168.10.0/24 -o $LAB_INTERFACE_NAME --to-source $LAB_INTERFACE_IP
    iptables -t nat -A PREROUTING -j DNAT -i $LAB_INTERFACE_NAME --to-destination $CLIENT_IP
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

    iptables -P INPUT DROP
	iptables -P OUTPUT DROP
    iptables -P FORWARD DROP

    for port in $TCP_ALWAYS_BLOCKED_PORTS
	do
		iptables -A FORWARD -j DROP -p tcp -s 192.168.0.0/24 --dport $port 
		iptables -A FORWARD -j DROP -p tcp -s $LAB_INTERFACE_IP --dport $port
    done

    for port in $UDP_ALWAYS_BLOCKED_PORTS
	do
		iptables -A FORWARD -j DROP -p udp -s 192.168.0.0/24 --dport $port 
		iptables -A FORWARD -j DROP -p udp -s $LAB_INTERFACE_IP --dport $port
    done
    
    for type in $ICMP_ALWAYS_BLOCKED_TYPES
	do
		iptables -A FORWARD -j DROP -p icmp -s 192.168.0.0/24 --icmp-type $type 
		iptables -A FORWARD -j DROP -p icmp -s $LAB_INTERFACE_IP --icmp-type $type
    done

    for port in $TCP_ALLOWED_PORTS
	do
		iptables -A FORWARD -j ACCEPT -p tcp -s 192.168.0.0/24 --dport $port 
		iptables -A FORWARD -j ACCEPT -p tcp -s $LAB_INTERFACE_IP --dport $port
    done

    for port in $UDP_ALLOWED_PORTS
	do
		iptables -A FORWARD -j ACCEPT -p udp -s 192.168.0.0/24 --dport $port 
		iptables -A FORWARD -j ACCEPT -p udp -s $LAB_INTERFACE_IP --dport $port
    done
    
    for type in $ICMP_ALLOWED_TYPES
	do
		iptables -A FORWARD -j ACCEPT -p icmp -s 192.168.0.0/24 --icmp-type $type 
		iptables -A FORWARD -j ACCEPT -p icmp -s $LAB_INTERFACE_IP --icmp-type $type
    done

    
}

function forwardChain2(){
    portRangeOpperation $TCP_ALWAYS_BLOCKED_PORTS "DROP" "tcp" "--dport"
    portRangeOpperation $UDP_ALWAYS_BLOCKED_PORTS "DROP" "udp" "--dport"
    portRangeOpperation $ICMP_ALWAYS_BLOCKED_PORTS "DROP" "icmp" "--icmp-type"

    portRangeOpperation $TCP_ALLOWED_PORTS "ALLOW" "tcp" "--dport"
    portRangeOpperation $UDP_ALLOWED_PORTS "ALLOW" "udp" "--dport"
    portRangeOpperation $ICMP_ALLOWED_PORTS "ALLOW" "icmp" "--icmp-type"
}

function portRangeOpperation(){
    for item in $1
	do
		iptables -A FORWARD -j $2 -p $3 $4 $item -s 192.168.0.0/24  
		iptables -A FORWARD -j $2 -p $3 $4 $item -s $LAB_INTERFACE_IP
    done
}



clearIptables
init
#forwardChain



