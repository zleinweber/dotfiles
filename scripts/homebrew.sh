#!/usr/bin/env bash

## homebrew.sh ##
#
# Script to run common homebrew tasks. Available commands:
# - `install` - Install homebrew if it's not already installed
#

## Globals ##
HOMEBREW_INSTALL_SCRIPT_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"

## Functions ##
function usage () {
    echo "Usage: $0 install"
}

function install () {
    if command -v brew > /dev/null 2>&1; then
        echo "Homebrew is already installed"
    else
        echo "Installing homebrew via curl bash: $HOMEBREW_INSTALL_SCRIPT_URL"
        /bin/bash -c "$(curl -fsSL "$HOMEBREW_INSTALL_SCRIPT_URL")"   
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
        ;;
esac
