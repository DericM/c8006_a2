LAB_INTERFACE_NAME=eno1
LAB_INTERFACE_IP=$(ifconfig $LAB_INTERFACE_NAME | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p')

LOCAL_INTERFACE_NAME=enp3s2
LOCAL_INTERFACE_IP=192.168.10.2

LOCAL_INTERFACE_GATEWAY_IP=192.168.10.1

echo "Flushing rules"
#ip route del default
#ip addr flush dev $LOCAL_INTERFACE_NAME

echo "Deactivate $LAB_INTERFACE_NAME"
ip link set $LAB_INTERFACE_NAME down

echo "Assign $LOCAL_INTERFACE_IP to $LOCAL_INTERFACE_NAME"
ip addr add $LOCAL_INTERFACE_IP dev $LOCAL_INTERFACE_NAME

echo "Activate $LOCAL_INTERFACE_NAME"
ip link set $LOCAL_INTERFACE_NAME up

echo "Set default gateway to $LOCAL_INTERFACE_GATEWAY_IP"
ip route add default via $LOCAL_INTERFACE_GATEWAY_IP dev $LOCAL_INTERFACE_NAME
