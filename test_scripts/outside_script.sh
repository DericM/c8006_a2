#!/bin/bash

#
# GLOBAL VARIABLES
#
SCAN_RESULTS="scan_results"
SCAN_RESULTS_SYN="$SCAN_RESULTS/syn_scan"
#
#
#


indent() { sed 's/^/  /'; }

bold=$(tput bold)
normal=$(tput sgr0)

function bold_text() {
    echo "${bold}$1${normal}"
}

function build_env() {
    echo Installing {$(bold_text "Development Tools and Development Libraries")}
    dnf groupinstall -y "Development Tools" "Development Libraries"
    dnf install -y openssl-devel
    dnf install -y tcpdump

    echo $(bold_text "Reinstalling nmap")
    dnf autoremove -y nmap | indent
    dnf install -y nmap    | indent

    echo $(bold_text "Resetting the folder structure")
    echo Deleting folder $(bold_text $SCAN_RESULTS) | indent
    rm -rf ./$SCAN_RESULTS
    echo Creating folder $(bold_text $SCAN_RESULTS) | indent
    mkdir ./$SCAN_RESULTS
}

function syn_scan() {
    rm -rf ./$SCAN_RESULTS_SYN
    mkdir ./$SCAN_RESULTS_SYN

    sudo tcpdump host $1 -w ./$SCAN_RESULTS_SYN/packets &
    sudo nmap -sS -Pn -p- -T4 -vv --reason -oN ./$SCAN_RESULTS_SYN/nmap.results $1
    killall tcpdump
}


if [ $1 = "start" ]; then
    if [ $2 != "" ]; then
        echo Starting Tests on $(bold_text $2)
        syn_scan $2
    else
        echo Target Missing!
    fi
elif [ $1 = "config" ]; then
    echo Configuring Environment
    build_env | indent
else
    echo No Inputs!
fi
