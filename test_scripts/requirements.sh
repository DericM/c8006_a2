

SERVER_PUBLIC_IP=192.168.0.13

TCP_ALLOWED_PORTS="80 8080 22 443 53"
UDP_ALLOWED_PORTS="221 322 53"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color


function test_tcp_ports(){
    for port in $TCP_ALLOWED_PORTS
    do
        hping3 -c 3 -p $port $SERVER_PUBLIC_IP

        #if [ $? -eq 0 ]
        #then
        #	echo -e "${GREEN}PASS${NC}"
        #else
        #    echo -e "${RED}FAIL${NC}"
        #fi
    done
}

function run_tests(){
    test_tcp_ports
}

run_tests
