#!/usr/bin/env bash

## homebrew.sh ##
#
# Script to run common homebrew tasks. Available commands:
#

## Globals ##
HOMEBREW_INSTALL_SCRIPT_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"

## Functions ##
function usage () {
    echo "Usage: $0 install|bundle"
    echo ""
    echo "Commands:"
    echo "  install - Install homebrew if it's not already installed"
    echo "  bundle - Install packages from a Brewfile bundle"
}

function check_if_brew_is_installed () {
    if command -v brew > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

function install () {
    if check_if_brew_is_installed; then
        echo "Homebrew is already installed"
    else
        echo "Installing homebrew via curl bash: $HOMEBREW_INSTALL_SCRIPT_URL"
        /bin/bash -c "$(curl -fsSL "$HOMEBREW_INSTALL_SCRIPT_URL")"
    fi
}

function bundle () {
    if check_if_brew_is_installed; then
        brew bundle
    else
        echo "ERROR: brew is not installed"
        return 1
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
    bundle)
        bundle
        ;;
    install)
        install
        ;;
    *)
        echo "ERROR: Invalid command '$command'"
        usage
        exit 1
        ;;
esac
