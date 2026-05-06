#!/usr/bin/env bash

set -o pipefail

## Globals ##
RIPGREP_VERSION="${RIPGREP_VERSION:-latest}"
RIPGREP_INSTALL_DIR="${RIPGREP_INSTALL_DIR:-/usr/local/bin}"
RIPGREP_FORCE_INSTALL="${RIPGREP_FORCE_INSTALL:-true}"

## Functions ##
source ./scripts/common.sh

function usage () {
    echo "Usage: $0 {install|remove} | help"
    echo ""
    echo "Install ripgrep from the GitHub release tarball."
    echo "Supports Linux x86_64/amd64 and arm64/aarch64 systems."
    echo ""
    echo "Environment:"
    echo "  RIPGREP_VERSION       Release version to install, or latest (default: latest)"
    echo "  RIPGREP_INSTALL_DIR   Directory for rg binary (default: /usr/local/bin)"
    echo "  RIPGREP_FORCE_INSTALL Reinstall when rg already exists (default: true)"
    echo ""
    echo "Commands:"
    echo "  install - Install ripgrep"
    echo "  remove  - Remove ripgrep"
    echo "  help    - Display this help message"
}

function check_supported_platform () {
    local platform="$1"
    local arch="$2"

    if [ "$platform" != "linux" ]; then
        echo_error "Unsupported ripgrep platform: $platform"
        return 1
    fi

    case "$arch" in
        x86_64|arm64)
            ;;
        *)
            echo_error "Unsupported ripgrep architecture: $arch"
            return 1
            ;;
    esac
}

function ripgrep_target () {
    local arch="$1"

    case "$arch" in
        x86_64)
            echo "x86_64-unknown-linux-musl"
            ;;
        arm64)
            echo "aarch64-unknown-linux-gnu"
            ;;
        *)
            echo_error "Unsupported ripgrep target architecture: $arch"
            return 1
            ;;
    esac
}

function resolve_ripgrep_version () {
    local ripgrep_version="$1"

    if [ "$ripgrep_version" = "latest" ]; then
        curl -fLsS -o /dev/null -w '%{url_effective}' https://github.com/BurntSushi/ripgrep/releases/latest \
            | sed 's#.*/tag/##'
    else
        echo "$ripgrep_version"
    fi
}

function ripgrep_download_url () {
    local ripgrep_version="$1"
    local target="$2"
    local asset_name="ripgrep-${ripgrep_version}-${target}.tar.gz"

    echo "https://github.com/BurntSushi/ripgrep/releases/download/${ripgrep_version}/${asset_name}"
}

function check_if_ripgrep_installed () {
    local ripgrep_install_dir="$1"

    if [ -x "${ripgrep_install_dir}/rg" ]; then
        return 0
    else
        return 1
    fi
}

function install_ripgrep () {
    local ripgrep_version="$1"
    local ripgrep_install_dir="$2"
    local platform
    local arch
    local target
    local resolved_version
    local download_url
    local tmp_dir
    local extracted_dir

    platform="$(detect_platform)" || exit 1
    arch="$(detect_arch)" || exit 1
    check_supported_platform "$platform" "$arch" || exit 1

    if check_if_ripgrep_installed "$ripgrep_install_dir"; then
        echo_info "ripgrep is already installed"
        if "$RIPGREP_FORCE_INSTALL"; then
            echo_info "Forcing re-installation"
        else
            exit 0
        fi
    fi

    target="$(ripgrep_target "$arch")" || exit 1
    resolved_version="$(resolve_ripgrep_version "$ripgrep_version")" || exit 1
    download_url="$(ripgrep_download_url "$resolved_version" "$target")"
    tmp_dir="$(mktemp -d -t ripgrep-XXXXXXXXXX)"
    extracted_dir="${tmp_dir}/ripgrep-${resolved_version}-${target}"

    echo_info "Installing ripgrep ${resolved_version} from ${download_url}"
    if ! curl -fLsS "$download_url" | tar -C "$tmp_dir" -xzf -; then
        rm -rf "$tmp_dir"
        return 1
    fi

    if ! sudo install -m 0775 "${extracted_dir}/rg" "${ripgrep_install_dir}/rg"; then
        rm -rf "$tmp_dir"
        return 1
    fi

    rm -rf "$tmp_dir"
}

function remove_ripgrep () {
    local ripgrep_install_dir="$1"

    sudo rm -f "${ripgrep_install_dir}/rg"
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
        install_ripgrep "$RIPGREP_VERSION" "$RIPGREP_INSTALL_DIR"
        ;;
    remove)
        remove_ripgrep "$RIPGREP_INSTALL_DIR"
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
