#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

## Functions ##
function usage () {
    echo "Usage: $0 install|help"
    echo ""
    echo "Install atuin (see also https://docs.atuin.sh/guide/installation/)"
    echo ""
    echo "Commands:"
    echo "  install - Install atuin"
    echo "  help    - Display this help message"
}

function check_if_atuin_installed () {
    if command -v atuin > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

function install () {
    if check_if_atuin_installed; then
        echo "atuin is already installed"
    else
        echo "Installing atuin via curl bash: https://setup.atuin.sh"
        bash <(curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh)
    fi
}

## Main ##
command="$1"

if [ -z "$command" ]; then
    echo "ERROR: Missing argument 'command'"
    usage
    exit 1
fi

case $command in
    install)
        install
        ;;
    help)
        usage
        ;;
    *)
        echo "ERROR: Invalid command '$command'"
        usage
        exit 1
esac
