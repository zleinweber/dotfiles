#!/usr/bin/env bash

## Globals ##
export DEBIAN_FRONTEND=noninteractive

## Functions ##
source ./scripts/common.sh

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
        echo_error "apt is not installed"
        exit 1
    fi
}

function manage_apt_pacakges () {
    local operation="$1"; shift
    local packages=("$@")

    if [ -z "$operation" ]; then
        echo_error "Missing argument 'operation'"
        usage
        exit 1
    fi

    if [ -z "${packages[*]:-}" ]; then
        echo_error "Missing argument 'package'"
        usage
        exit 1
    fi

    if [[ ! $operation =~ install|remove ]]; then
        echo_error "Invalid operation '$operation'"
        usage
        exit 1
    fi

    echo_info: "Running apt-get $operation for packages: ${packages[*]}"
    sudo apt-get update
    sudo DEBIAN_FRONTEND=noninteractive apt-get "$operation" -y "${packages[@]}"
}

function cleanup_apt () {
    echo_info "Cleaning apt cache and removing unused packages"
    sudo DEBIAN_FRONTEND=noninteractive apt-get autoremove -y
    sudo apt-get clean
    sudo rm -rf /var/lib/apt/lists/*
}

function apt_upgrade () {
    echo_info "Upgrading all installed packages"
    sudo apt-get update
    sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
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
        echo_error "Invalid command '$command'"
        usage
        exit 1
        ;;
esac
