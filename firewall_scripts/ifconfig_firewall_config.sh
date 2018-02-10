
LAB_INTERFACE_NAME=eno1
LAB_INTERFACE_IP=$(ifconfig $LAB_INTERFACE_NAME | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p')

LOCAL_INTERFACE_NAME=enp3s2
LOCAL_INTERFACE_IP=192.168.10.1


#ip addr flush dev $LAB_INTERFACE_NAME
#ip addr flush dev $LOCAL_INTERFACE_NAME

sudo echo "Activate $LOCAL_INTERFACE_NAME with ip: $LOCAL_INTERFACE_IP"
sudo ifconfig $LOCAL_INTERFACE_NAME $LOCAL_INTERFACE_IP up

sudo echo "Set ip_forward flag."
sudo echo "1" >/proc/sys/net/ipv4/ip_forward


sudo echo "Allow routing from this computer to lab computers"
sudo route add -net 192.168.0.0 netmask 255.255.255.0 gw $LAB_INTERFACE_IP

sudo echo "Allow routing from local computers to Firewall gateway"
sudo route add -net 192.168.10.0/24 gw $LOCAL_INTERFACE_IP
