#!/usr/bin/env bash

set -euo pipefail

## Globals ##
NVIM_INSTALL_DIR="${NVIM_INSTALL_DIR:-/opt}"
NVIM_STOW_DIR="${NVIM_STOW_DIR:-/usr/local}"
NVIM_FORCE_INSTALL="${NVIM_FORCE_INSTALL:-false}"

## Functions ##
# shellcheck source=scripts/common.sh
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/common.sh"

function default_nvim_dist () {
    local arch

    arch="$(detect_arch)" || return 1

    case "$arch" in
        x86_64)
            echo "nvim-linux-x86_64"
            ;;
        arm64)
            echo "nvim-linux-arm64"
            ;;
        *)
            echo_error "Unsupported Neovim architecture: $arch"
            return 1
            ;;
    esac
}

function usage () {
    echo "Usage: $0 {install|remove} | help"
    echo ""
    echo "Install neovim from the latest binary release tarball."
    echo "Supports Linux x86_64/amd64 and arm64/aarch64 systems."
    echo ""
    echo "Commands:"
    echo "  install - Install neovim"
    echo "  remove  - Remove neovim"
    echo "  help    - Display this help message"
}

function download_neovim () {
    local nvim_url="$1"
    local nvim_dir="$2"

    curl -fLsS "$nvim_url" | tar -C "$nvim_dir" -xzf -
}

function remove_neovim () {
    local nvim_dir="$1"

    sudo rm -rf "$nvim_dir"
}

function stow_neovim () {
    local nvim_install_dir="$1"
    local stow_dir="$2"
    local stow_package="$3"

    sudo stow -d "$nvim_install_dir" -t "$stow_dir" "$stow_package"
}

function unstow_neovim () {
    local nvim_install_dir="$1"
    local stow_dir="$2"
    local stow_package="$3"

    sudo stow -D -d "$nvim_install_dir" -t "$stow_dir" "$stow_package"
}

## Main ##
parse_command "install:0 remove:0" "$@"
command="${1:-help}"
if [ "$#" -gt 0 ]; then
    shift
fi

if [ -z "${NVIM_DIST:-}" ]; then
    NVIM_DIST="$(default_nvim_dist)" || exit 1
fi

NVIM_DIR="${NVIM_INSTALL_DIR}/${NVIM_DIST}"
NVIM_TARBALL="${NVIM_DIST}.tar.gz"
NVIM_TARBALL_URL="${NVIM_TARBALL_URL:-https://github.com/neovim/neovim/releases/latest/download/${NVIM_TARBALL}}"

case "$command" in
    install)
        if [ -d "$NVIM_DIR" ]; then
            echo_info "Neovim is already installed"
            if is_true "$NVIM_FORCE_INSTALL"; then
                echo_info "Forcing re-installation"
                unstow_neovim "$NVIM_INSTALL_DIR" "$NVIM_STOW_DIR" "$NVIM_DIST"
                remove_neovim "$NVIM_DIR"
            else
                exit 0
            fi
        fi

        download_neovim "$NVIM_TARBALL_URL" "$NVIM_INSTALL_DIR"
        stow_neovim "$NVIM_INSTALL_DIR" "$NVIM_STOW_DIR" "$NVIM_DIST"
        ;;
    remove)
        unstow_neovim "$NVIM_INSTALL_DIR" "$NVIM_STOW_DIR" "$NVIM_DIST"
        remove_neovim "$NVIM_DIR"
        ;;
    help)
        usage
        ;;
    *)
        echo_error "Invalid command: $command"
        usage
        exit 1
        ;;
esac
