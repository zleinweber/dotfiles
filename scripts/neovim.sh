#!/usr/bin/env bash

## Globals ##
NVIM_INSTALL_DIR="${/opt}"
NVIM_STOW_DIR="${NVIM_STOW_DIR:-/usr/local}"
NVIM_DIST="nvim-linux64"
NVIM_DIR="${NVIM_INSTALL_DIR}/${NVIM_DIST}"
NVIM_TARBALL="${NVIM_DIST}.tar.gz"
NVIM_TARBALL_URL="https://github.com/neovim/neovim/releases/latest/download/${NVIM_TARBALL}"

## Functions ##
function usage () {
    echo "Usage: $0 {install|remove} | help"
    echo ""
    echo "Manage neovim"
    echo ""
    echo "Commands:"
    echo "  install - Install neovim"
    echo "  remove  - Remove neovim"
    echo "  help    - Display this help message"
}

function download_neovim () {
    local nvim_url="$1"
    local nvim_dir="$2"

    curl -L "$nvim_url" | tar -C "$nvim_dir" -xzf -
}

function remove_neovim () {
    local nvim_dir="$1"

    sudo rm -rf "$nvim_dir"
}

function stow_neovim () {
    local nvim_install_dir="$1"
    local stow_dir="$2"

    sudo stow -d "$nvim_install_dir" -t "$stow_dir" neovim
}

function unstow_neovim () {
    local nvim_install_dir="$1"
    local stow_dir="$2"

    sudo stow -D -d "$nvim_install_dir" -t "$stow_dir" neovim
}
