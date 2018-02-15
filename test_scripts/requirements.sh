#!/bin/sh
source ../config.sh


function test__allowed_tcp_ports(){
    for port in $TCP_ALLOWED_PORTS
    do
        hping3 -c 1 -q -S -p $port $SERVER_PUBLIC_IP > /dev/null 2>&1
        success=$?
        if [[ $success != 0 ]]
        then
            echo -e "$SERVER_PUBLIC_IP:$(bt $port) TEST: $(rt FAILED)"
        else
            echo -e "$SERVER_PUBLIC_IP:$(bt $port) TEST: $(gt PASSED)"
        fi
    done
}

function test_allowed_udp_ports(){
    for port in $UDP_ALLOWED_PORTS
    do
        hping3 -c 1 -q -p $port --udp $SERVER_PUBLIC_IP > /dev/null 2>&1
        success=$?
        if [[ $success != 0 ]]
        then
            echo -e "$SERVER_PUBLIC_IP:$(bt $port) TEST: $(rt FAILED)"
        else
            echo -e "$SERVER_PUBLIC_IP:$(bt $port) TEST: $(gt PASSED)"
        fi
    done
}

function test_allowed_icmp_ports(){
    for type in $ICMP_ALLOWED_TYPES
    do
        hping3 -c 1 -C $type $SERVER_PUBLIC_IP > /dev/null 2>&1
        success=$?
        if [[ $success != 0 ]]
        then
            echo -e "$SERVER_PUBLIC_IP:$(bt $type) TEST: $(rt FAILED)"
        else
            echo -e "$SERVER_PUBLIC_IP:$(bt $type) TEST: $(gt PASSED)"
        fi
    done
}


function test_blocked_tcp_ports(){
    for port in $TCP_BLOCKED_PORTS
    do
        hping3 -c 1 -q -S -p $port $SERVER_PUBLIC_IP > /dev/null 2>&1
        success=$?
        if [[ $success == 0 ]]
        then
            echo -e "$SERVER_PUBLIC_IP:$(bt $port) TEST: $(rt FAILED)"
        else
            echo -e "$SERVER_PUBLIC_IP:$(bt $port) TEST: $(gt PASSED)"
        fi
    done
}

function test_blocked_udp_ports(){
    for port in $UDP_BLOCKED_PORTS
    do
        hping3 -c 1 -q -p $port --udp $SERVER_PUBLIC_IP > /dev/null 2>&1
        success=$?
        if [[ $success == 0 ]]
        then
            echo -e "$SERVER_PUBLIC_IP:$(bt $port) TEST: $(rt FAILED)"
        else
            echo -e "$SERVER_PUBLIC_IP:$(bt $port) TEST: $(gt PASSED)"
        fi
    done
}

function test_blocked_icmp_ports(){
    for type in $ICMP_BLOCKED_TYPES
    do
        hping3 -c 1 -C $type $SERVER_PUBLIC_IP > /dev/null 2>&1
        success=$?
        if [[ $success == 0 ]]
        then
            echo -e "$SERVER_PUBLIC_IP:$(bt $type) TEST: $(rt FAILED)"
        else
            echo -e "$SERVER_PUBLIC_IP:$(bt $type) TEST: $(gt PASSED)"
        fi
    done
}


function run_tests(){
    SERVER_PUBLIC_IP=$1
    echo
    echo "$(bt Scanning) $(gt ALLOWED) $(bt TCP) Ports"
    test__allowed_tcp_ports | indent

    echo
    echo "$(bt Scanning) $(gt ALLOWED) $(bt UDP) Ports"
    test_allowed_udp_ports | indent

    echo
    echo "$(bt Scanning) $(gt ALLOWED) $(bt ICMP) Types"
    test_allowed_icmp_ports | indent

    echo
    echo "$(bt Scanning) $(rt BLOCKED) $(bt TCP) Ports"
    test_blocked_tcp_ports | indent

    echo
    echo "$(bt Scanning) $(rt BLOCKED) $(bt UDP) Ports"
    test_blocked_udp_ports | indent

    echo
    echo "$(bt Scanning) $(rt BLOCKED) $(bt ICMP) Ports"
    test_blocked_icmp_ports | indent

}

function main() {
    run_tests $1
}

if [[ $1 == "" ]]
then
    echo "Please Enter Target"
else
    main $1
fi
