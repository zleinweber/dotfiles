#!/usr/bin/env bash

## Globals ##
export DEBIAN_FRONTEND=noninteractive

## Functions ##
function usage () {
    echo "Usage: $0 {install|remove} <package...> | {clean|upgrade|help}"
    echo ""
    echo "Managed apt packages"
    echo ""
    echo "Commands:"
    echo "  clean   - Clean apt cache and remove unused packages"
    echo "  install - Install apt packages"
    echo "  remove  - Remove apt packages"
    echo "  upgrade - Upgrade all installed packages"
    echo "  help    - Display this help message"
}

function check_if_apt_installed () {
    if ! command -v apt-get > /dev/null 2>&1; then
        echo "ERROR: apt is not installed"
        exit 1
    fi
}

function manage_apt_pacakges () {
    local operation="$1"; shift
    local packages=("$@")

    if [ -z "$operation" ]; then
        echo "ERROR: Missing argument 'operation'"
        usage
        exit 1
    fi

    if [ -z "${packages[*]:-}" ]; then
        echo "ERROR: Missing argument 'package'"
        usage
        exit 1
    fi

    if [[ ! $operation =~ install|remove ]]; then
        echo "ERROR: Invalid operation '$operation'"
        usage
        exit 1
    fi

    sudo apt-get update
    sudo apt-get "$operation" -y "${packages[@]}"
}

function cleanup_apt () {
    sudo apt-get autoremove -y
    sudo apt-get clean
    sudo rm -rf /var/lib/apt/lists/*
}

function apt_upgrade () {
    sudo apt-get update
    sudo apt-get upgrade -y
}

## Main ##
check_if_apt_installed
command="$1"; shift

case $command in
    clean)
        cleanup_apt
        ;;
    install)
        manage_apt_pacakges install "$@"
        ;;
    remove)
        manage_apt_pacakges  remove "$@"
        ;;
    upgrade)
        apt_upgrade
        ;;
    help)
        usage
        ;;
    *)
        echo "ERROR: Invalid command '$command'"
        usage
        exit 1
        ;;
esac
