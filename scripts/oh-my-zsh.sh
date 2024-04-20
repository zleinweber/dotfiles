#!/usr/bin/env bash

## Globals ##
ZSH_INSTALL_SCRIPT_URL="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"

## Functions ##
source ./scripts/common.sh

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
        echo_info "oh-my-zsh is already installed"
        return
    fi
    echo_info "Installing oh-my-zsh via curl bash: $ZSH_INSTALL_SCRIPT_URL"
    /bin/bash -c "$(curl -fsSL "$ZSH_INSTALL_SCRIPT_URL")"
}

## Main ##
command="$1"

if [ -z "$command" ]; then
    echo_error "Missing argument 'command'"
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
        echo_error "Invalid command '$command'"
        usage
        exit 1
        ;;
esac
