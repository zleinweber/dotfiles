#!/usr/bin/env bash

set -euo pipefail

## Globals ##
ZSH_INSTALL_SCRIPT_URL="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"

## Functions ##
# shellcheck source=scripts/common.sh
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/common.sh"

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
    local installer
    installer="$(curl -fsSL "$ZSH_INSTALL_SCRIPT_URL")"
    /bin/bash -c "$installer"
}

## Main ##
parse_command "install:0" "$@"
command="${1:-help}"
if [ "$#" -gt 0 ]; then
    shift
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
