#!/usr/bin/env bash

## Globals ##
ZSH_INSTALL_SCRIPT_URL="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"

## Functions ##
function usage () {
    echo "Usage: $0 install|help"
    echo ""
    echo "Install oh-my-zsh"
    echo ""
    echo "Commands:"
    echo "  install - Install oh-my-zsh and set zsh as the default shell"
    echo "  help    - Display this help message"
}

function install () {
    if [ -d "$HOME/.oh-my-zsh" ]; then
        echo "oh-my-zsh is already installed"
        return
    fi
    echo "Installing oh-my-zsh via curl bash: $ZSH_INSTALL_SCRIPT_URL"
    /bin/bash -c "$(curl -fsSL "$ZSH_INSTALL_SCRIPT_URL")"
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
        ;;
esac
