#!/usr/bin/env bash

## atuin.sh ##
#
# This script install atuin via the installation script
# See also: https://docs.atuin.sh/guide/installation/
#

export DEBIAN_FRONTEND=noninteractive

## Functions ##
function usage () {
    echo "Usage: $0 install"
    echo ""
    echo "Commands:"
    echo "  install - Install atuin"
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
    *)
        echo "ERROR: Invalid command '$command'"
        usage
        exit 1
esac
