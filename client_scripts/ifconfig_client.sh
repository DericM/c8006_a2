LAB_INTERFACE_NAME=eno1
LAB_INTERFACE_IP=$(ifconfig $LAB_INTERFACE_NAME | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p')

LOCAL_INTERFACE_NAME=enp3s2
LOCAL_INTERFACE_IP=192.168.10.2

LOCAL_INTERFACE_GATEWAY_IP=192.168.10.1

echo "Flushing rules"
#ip route del default
#ip addr flush dev $LOCAL_INTERFACE_NAME

echo "Deactivate $LAB_INTERFACE_NAME"
ifconfig $LAB_INTERFACE_NAME down

echo "Enable the second NIC that is connected to the firewall on $LOCAL_INTERFACE_IP"
ifconfig p3p1 $LOCAL_INTERFACE_IP up

echo "Add a routing rule to route the firewall host as the default gateway for $LOCAL_INTERFACE_GATEWAY_IP"
route add default gw $LOCAL_INTERFACE_GATEWAY_IP
