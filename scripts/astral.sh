#!/usr/bin/env bash

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

## Functions ##
# shellcheck source=scripts/common.sh
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/common.sh"

function usage () {
    echo "Usage: $0 install|help"
    echo ""
    echo "Install uv / ruff (see also https://astral.sh/)"
    echo ""
    echo "Commands:"
    echo "  install - Install uv and ruff"
    echo "  help    - Display this help message"
}

function check_if_installed () {
    local cmd="$1"
    if command -v "$cmd" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

function install_astral_sh_tool () {
    local cmd="$1"
    case $cmd in
        uv)
            if check_if_installed uv; then
                echo_info "uv is already installed"
            else
                echo_info "Installing uv"
                wget -qO- https://astral.sh/uv/install.sh | sh
            fi
            ;;
        ruff)
            if check_if_installed ruff; then
                echo_info "ruff is already installed"
            else
                if ! check_if_installed uv; then
                    echo_error "uv is required to install ruff. Please install uv first."
                    return 1
                fi
                echo_info "Installing ruff"
                uv tool install ruff@latest
            fi
            ;;
        *)
            echo_error "Unknown command '$cmd' for install_astral_sh"
            return 1
    esac
}

## Main ##
parse_command "install:0" "$@"
command="${1:-help}"
if [ "$#" -gt 0 ]; then
    shift
fi

case $command in
    install)
        install_astral_sh_tool uv
        install_astral_sh_tool ruff
        ;;
    help)
        usage
        ;;
    *)
        echo_error "Invalid command '$command'"
        usage
        exit 1
esac
