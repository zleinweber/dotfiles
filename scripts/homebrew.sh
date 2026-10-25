#!/usr/bin/env bash

set -euo pipefail

## Globals ##
HOMEBREW_INSTALL_SCRIPT_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"

## Functions ##
# shellcheck source=scripts/common.sh
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/common.sh"

function usage () {
    echo "Usage: $0 install|bundle|help"
    echo ""
    echo "Manage homebrew packages"
    echo ""
    echo "Commands:"
    echo "  install - Install homebrew if it's not already installed"
    echo "  bundle  - Install packages from a Brewfile bundle"
    echo "  help    - Display this help message"
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
        echo_info "Homebrew is already installed"
    else
        echo_info "Installing homebrew via curl bash: $HOMEBREW_INSTALL_SCRIPT_URL"
        local installer
    installer="$(curl -fsSL "$HOMEBREW_INSTALL_SCRIPT_URL")"
    /bin/bash -c "$installer"
    fi
}

function bundle () {
    if check_if_brew_is_installed; then
        brew bundle --file="${HOMEBREW_BUNDLE_FILE:-$DOTFILES_ROOT/Brewfile}"
    else
        echo_error "brew is not installed"
        return 1
    fi
}

## Main ##
parse_command "install:0 bundle:0" "$@"
command="${1:-help}"
if [ "$#" -gt 0 ]; then
    shift
fi

case $command in
    bundle)
        bundle
        ;;
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
