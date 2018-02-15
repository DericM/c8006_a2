SERVER_PUBLIC_IP=192.168.10.1

TCP_ALLOWED_PORTS="80 8080 22 443 53 2222"
UDP_ALLOWED_PORTS="221 322 53"




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
        hping3 -c 1 -q -p $port $SERVER_PUBLIC_IP > /dev/null 2>&1
        success=$?
        if [[ $success != 0 ]]
        then
            echo -e "$SERVER_PUBLIC_IP:$(bt $port) TEST: $(rt FAILED)"
        else
            echo -e "$SERVER_PUBLIC_IP:$(bt $port) TEST: $(gt PASSED)"
        fi
    done
}




function run_tests(){
    echo
    echo "$(bt Scanning) $(gt ALLOWED) $(bt TCP) Ports"
    test__allowed_tcp_ports | indent

    echo
    echo "$(bt Scanning) $(gt ALLOWED) $(bt UDP) Ports"
    test_allowed_udp_ports | indent


}

function main() {
    run_tests
}

main
