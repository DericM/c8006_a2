#!/bin/bash
TCP_ALLOWED_PORTS="80 8080 22 443 53"
UDP_ALLOWED_PORTS="221 322 53"


# Formatting
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
