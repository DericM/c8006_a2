LAB_INTERFACE_NAME=eno1
LAB_INTERFACE_IP=$(ifconfig $LAB_INTERFACE_NAME | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p')

LOCAL_INTERFACE_NAME=enp3s2
LOCAL_INTERFACE_IP=192.168.10.1


#ip addr flush dev $LAB_INTERFACE_NAME
#ip addr flush dev $LOCAL_INTERFACE_NAME

sudo echo "Assign $LOCAL_INTERFACE_IP to interface $LOCAL_INTERFACE_NAME"
sudo ip addr add $LOCAL_INTERFACE_IP dev $LOCAL_INTERFACE_NAME

sudo echo "Activate $LOCAL_INTERFACE_NAME"
sudo ip link set $LOCAL_INTERFACE_NAME up

sudo echo "Set ip_forward flag."
sudo echo "1" >/proc/sys/net/ipv4/ip_forward

sudo echo "Allow routing from this computer to lab computers"
sudo ip route add 192.168.0.0/24 via $LAB_INTERFACE_IP dev $LAB_INTERFACE_NAME

sudo echo "Allow routing from local computers to lab computers"
#sudo ip route add 192.168.0.0/24 via $LOCAL_INTERFACE_IP dev $LAB_INTERFACE_NAME

sudo ip route add 192.168.0.0/24 via 192.168.0.100 dev $LAB_INTERFACE_NAME
 
