#!/usr/bin/env bash

set -euo pipefail

## Globals ##
NVIM_INSTALL_DIR="${NVIM_INSTALL_DIR:-$HOME/.local/stow}"
NVIM_STOW_DIR="${NVIM_STOW_DIR:-$HOME/.local}"
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
    echo ""
    echo "Configuration (directories must be writable by the current user):"
    echo "  NVIM_INSTALL_DIR    Package directory (default: ~/.local/stow)"
    echo "  NVIM_STOW_DIR       Link target prefix (default: ~/.local)"
    echo "  NVIM_FORCE_INSTALL  Reinstall/update when true (default: false)"
    echo "  NVIM_DIST           Archive directory name (default: detected Linux architecture)"
    echo "  NVIM_TARBALL_URL    Override the release archive URL"
    echo "Put the target prefix's bin directory on PATH (default: ~/.local/bin)."
}

function download_neovim () {
    local nvim_url="$1"
    local nvim_dir="$2"

    curl -fLsS "$nvim_url" | tar -C "$nvim_dir" -xzf -
}

function remove_neovim () {
    local nvim_dir="$1"

    rm -rf -- "$nvim_dir"
}

function stow_neovim () {
    local nvim_install_dir="$1"
    local stow_dir="$2"
    local stow_package="$3"

    stow --no-folding -d "$nvim_install_dir" -t "$stow_dir" "$stow_package"
}

function unstow_neovim () {
    local nvim_install_dir="$1"
    local stow_dir="$2"
    local stow_package="$3"

    stow --no-folding -D -d "$nvim_install_dir" -t "$stow_dir" "$stow_package"
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

# NVIM_DIST is also used as a directory name during replacement/removal.
if [[ ! "$NVIM_DIST" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]]; then
    echo_error "Invalid Neovim distribution directory: $NVIM_DIST"
    exit 1
fi
if [ -L "$NVIM_DIR" ]; then
    echo_error "Refusing to manage a symlinked Neovim package: $NVIM_DIR"
    exit 1
fi

case "$command" in
    install)
        mkdir -p "$NVIM_INSTALL_DIR" "$NVIM_STOW_DIR"
        if [ -d "$NVIM_DIR" ] && ! is_true "$NVIM_FORCE_INSTALL"; then
            if [ ! -x "$NVIM_DIR/bin/nvim" ] || [ ! -d "$NVIM_DIR/share/nvim/runtime" ]; then
                echo_error "Incomplete Neovim package; rerun with NVIM_FORCE_INSTALL=true"
                exit 1
            fi
            echo_info "Neovim is already installed; ensuring links exist"
            stow_neovim "$NVIM_INSTALL_DIR" "$NVIM_STOW_DIR" "$NVIM_DIST"
            exit 0
        fi

        # Stage the complete download before replacing a working installation.
        stage=$(mktemp -d "$NVIM_INSTALL_DIR/.nvim-download.XXXXXX")
        trap 'rm -rf -- "$stage"' EXIT
        download_neovim "$NVIM_TARBALL_URL" "$stage"
        if [ ! -x "$stage/$NVIM_DIST/bin/nvim" ] || [ ! -d "$stage/$NVIM_DIST/share/nvim/runtime" ]; then
            echo_error "Neovim archive is missing its executable or runtime"
            exit 1
        fi
        if [ -d "$NVIM_DIR" ]; then
            echo_info "Replacing Neovim installation"
            unstow_neovim "$NVIM_INSTALL_DIR" "$NVIM_STOW_DIR" "$NVIM_DIST"
            remove_neovim "$NVIM_DIR"
        fi
        mv -- "$stage/$NVIM_DIST" "$NVIM_DIR"
        stow_neovim "$NVIM_INSTALL_DIR" "$NVIM_STOW_DIR" "$NVIM_DIST"
        ;;
    remove)
        if [ -d "$NVIM_DIR" ]; then
            unstow_neovim "$NVIM_INSTALL_DIR" "$NVIM_STOW_DIR" "$NVIM_DIST"
            remove_neovim "$NVIM_DIR"
        fi
        ;;
esac
