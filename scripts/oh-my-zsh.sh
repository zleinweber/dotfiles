#!/usr/bin/env bash

## oh-my-zsh.sh ##
#
# Script to install oh-my-zsh and set zsh as the default shell
#

## Globals ##
ZSH_INSTALL_SCRIPT_URL="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"

## Functions ##
function usage () {
    echo "Usage: $0 install"
    echo ""
    echo "Commands:"
    echo "  install - Install oh-my-zsh and set zsh as the default shell"
}

function install () {
    echo "Installing oh-my-zsh via curl bash: $ZSH_INSTALL_SCRIPT_URL"
    /bin/bash -c "$(curl -fsSL "$ZSH_INSTALL_SCRIPT_URL")"
}

function set_zsh_as_default () {
    if [ "$SHELL" = "$(command -v zsh)" ]; then
        echo "zsh is already the default shell"
    else
        echo "Setting zsh as the default shell"
        chsh -s "$(command -v zsh)"
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
        set_zsh_as_default
        ;;
    *)
        echo "ERROR: Invalid command '$command'"
        usage
        exit 1
        ;;
esac
