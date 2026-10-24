#!/usr/bin/env bash

set -euo pipefail

## Functions ##
# shellcheck source=scripts/common.sh
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/common.sh"

function usage () {
    echo "Usage: $0 install|help"
    echo ""
    echo "Install codex cli via npm"
    echo ""
    echo "Commands:"
    echo "  install - Install codex cli via npm"
    echo "  help    - Display this help message"
}

function check_if_codex_cli_installed () {
    if command -v codex > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

function check_if_npm_installed () {
    if command -v npm > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

function install () {
    if check_if_codex_cli_installed; then
        echo_info "codex cli is already installed"
    else
        if ! check_if_npm_installed; then
            echo_error "npm is not installed. Please install npm first."
            exit 1
        fi

        echo_info "Installing codex cli via npm"
        npm install -g @openai/codex
    fi
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
esac
