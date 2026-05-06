#!/usr/bin/env bash

set -o pipefail

## Globals ##
LAZYGIT_VERSION="${LAZYGIT_VERSION:-latest}"
LAZYGIT_INSTALL_DIR="${LAZYGIT_INSTALL_DIR:-/usr/local/bin}"
LAZYGIT_FORCE_INSTALL="${LAZYGIT_FORCE_INSTALL:-true}"

## Functions ##
source ./scripts/common.sh

function usage () {
    echo "Usage: $0 {install|remove} | help"
    echo ""
    echo "Install lazygit from the GitHub release tarball."
    echo "Supports Linux x86_64/amd64 and arm64/aarch64 systems."
    echo ""
    echo "Environment:"
    echo "  LAZYGIT_VERSION       Release version to install, or latest (default: latest)"
    echo "  LAZYGIT_INSTALL_DIR   Directory for lazygit binary (default: /usr/local/bin)"
    echo "  LAZYGIT_FORCE_INSTALL Reinstall when lazygit already exists (default: true)"
    echo ""
    echo "Commands:"
    echo "  install - Install lazygit"
    echo "  remove  - Remove lazygit"
    echo "  help    - Display this help message"
}

function check_supported_platform () {
    local platform="$1"
    local arch="$2"

    if [ "$platform" != "linux" ]; then
        echo_error "Unsupported lazygit platform: $platform"
        return 1
    fi

    case "$arch" in
        x86_64|arm64)
            ;;
        *)
            echo_error "Unsupported lazygit architecture: $arch"
            return 1
            ;;
    esac
}

function resolve_lazygit_version () {
    local lazygit_version="$1"

    if [ "$lazygit_version" = "latest" ]; then
        curl -fLsS -o /dev/null -w '%{url_effective}' https://github.com/jesseduffield/lazygit/releases/latest \
            | sed 's#.*/tag/##'
    else
        echo "$lazygit_version"
    fi
}

function lazygit_download_url () {
    local lazygit_version="$1"
    local platform="$2"
    local arch="$3"
    local asset_version="${lazygit_version#v}"

    echo "https://github.com/jesseduffield/lazygit/releases/download/${lazygit_version}/lazygit_${asset_version}_${platform}_${arch}.tar.gz"
}

function check_if_lazygit_installed () {
    local lazygit_install_dir="$1"

    if [ -x "${lazygit_install_dir}/lazygit" ]; then
        return 0
    else
        return 1
    fi
}

function install_lazygit () {
    local lazygit_version="$1"
    local lazygit_install_dir="$2"
    local platform
    local arch
    local resolved_version
    local download_url
    local tmp_dir

    platform="$(detect_platform)" || exit 1
    arch="$(detect_arch)" || exit 1
    check_supported_platform "$platform" "$arch" || exit 1

    if check_if_lazygit_installed "$lazygit_install_dir"; then
        echo_info "lazygit is already installed"
        if "$LAZYGIT_FORCE_INSTALL"; then
            echo_info "Forcing re-installation"
        else
            exit 0
        fi
    fi

    resolved_version="$(resolve_lazygit_version "$lazygit_version")" || exit 1
    download_url="$(lazygit_download_url "$resolved_version" "$platform" "$arch")"
    tmp_dir="$(mktemp -d -t lazygit-XXXXXXXXXX)"

    echo_info "Installing lazygit ${resolved_version} from ${download_url}"
    curl -fLsS "$download_url" | tar -C "$tmp_dir" -xzf -
    sudo install -m 0775 "${tmp_dir}/lazygit" "${lazygit_install_dir}/lazygit"
    rm -rf "$tmp_dir"
}

function remove_lazygit () {
    local lazygit_install_dir="$1"

    sudo rm -f "${lazygit_install_dir}/lazygit"
}

## Main ##
command="$1"

if [ -z "$command" ]; then
    echo_error "Missing argument 'command'"
    usage
    exit 1
fi

case "$command" in
    install)
        install_lazygit "$LAZYGIT_VERSION" "$LAZYGIT_INSTALL_DIR"
        ;;
    remove)
        remove_lazygit "$LAZYGIT_INSTALL_DIR"
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
