#!/usr/bin/env bash

## Globals ##
NVIM_INSTALL_DIR="${NVIM_INSTALL_DIR:-/opt}"
NVIM_STOW_DIR="${NVIM_STOW_DIR:-/usr/local}"
NVIM_DIST="nvim-linux64"
NVIM_DIR="${NVIM_INSTALL_DIR}/${NVIM_DIST}"
NVIM_TARBALL="${NVIM_DIST}.tar.gz"
NVIM_TARBALL_URL="https://github.com/neovim/neovim/releases/latest/download/${NVIM_TARBALL}"
NVIM_FORCE_INSTALL="${NVIM_FORCE_INSTALL:-true}"

## Functions ##
source ./scripts/common.sh

function usage () {
    echo "Usage: $0 {install|remove} | help"
    echo ""
    echo "Install neovim from the latest binary release tarball."
    echo "The primary use case is for installing this on linux64 systems."
    echo ""
    echo "Commands:"
    echo "  install - Install neovim"
    echo "  remove  - Remove neovim"
    echo "  help    - Display this help message"
}

function download_neovim () {
    local nvim_url="$1"
    local nvim_dir="$2"

    curl -Ls "$nvim_url" | tar -C "$nvim_dir" -xzf -
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
command="$1"

if [ -z "$command" ]; then
    echo_error "Missing argument 'command'"
    usage
    exit 1
fi

case $command in
    install)
        if [ -d "$NVIM_DIR" ]; then
            echo_info "Neovim is already installed"
            if "$NVIM_FORCE_INSTALL"; then
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
