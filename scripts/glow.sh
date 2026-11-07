#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=scripts/common.sh
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/common.sh"

GLOW_VERSION="${GLOW_VERSION:-latest}"
GLOW_INSTALL_DIR="${GLOW_INSTALL_DIR:-$HOME/.local/bin}"
GLOW_FORCE_INSTALL="${GLOW_FORCE_INSTALL:-false}"

function usage () {
    echo "Usage: $0 install|remove|help"
    echo ""
    echo "Install Glow from GitHub binary releases (Linux/macOS, x86_64/arm64)."
    echo ""
    echo "Commands:"
    echo "  install - Install glow if missing"
    echo "  remove  - Remove glow from GLOW_INSTALL_DIR"
    echo "  help    - Display this help message"
    echo ""
    echo "Environment:"
    echo "  GLOW_VERSION       Release version, with or without v (default: latest)"
    echo "  GLOW_INSTALL_DIR   Writable binary directory (default: ~/.local/bin)"
    echo "  GLOW_FORCE_INSTALL Reinstall/update when true (default: false)"
    echo "Put GLOW_INSTALL_DIR on PATH to run glow."
}

function install_glow () (
    local platform arch version url archive stage dependency

    if ! is_true "$GLOW_FORCE_INSTALL"; then
        if [ -f "$GLOW_INSTALL_DIR/glow" ] && [ -x "$GLOW_INSTALL_DIR/glow" ]; then
            echo_info "glow is already installed"
            return 0
        fi
    fi

    platform="$(detect_platform)"
    arch="$(detect_arch)"
    case "$platform" in
        linux) platform=Linux ;;
        darwin) platform=Darwin ;;
    esac
    for dependency in curl tar mktemp install; do
        if ! command -v "$dependency" >/dev/null 2>&1; then
            echo_error "Required dependency is missing: $dependency"
            return 1
        fi
    done

    version="$GLOW_VERSION"
    if [ "$version" = latest ]; then
        url="$(curl -fLsS -o /dev/null -w '%{url_effective}' https://github.com/charmbracelet/glow/releases/latest)"
        version="${url##*/}"
    fi
    version="${version#v}"
    if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+([.-][a-zA-Z0-9.-]+)?$ ]]; then
        echo_error "Invalid Glow release version: $version"
        return 1
    fi
    archive="glow_${version}_${platform}_${arch}"
    url="https://github.com/charmbracelet/glow/releases/download/v${version}/${archive}.tar.gz"

    if [ -d "$GLOW_INSTALL_DIR/glow" ]; then
        echo_error "Glow destination is a directory: $GLOW_INSTALL_DIR/glow"
        return 1
    fi
    mkdir -p "$GLOW_INSTALL_DIR"
    stage="$(mktemp -d "$GLOW_INSTALL_DIR/.glow-download.XXXXXX")"
    trap 'rm -rf -- "$stage"' EXIT

    echo_info "Installing Glow v${version} from $url"
    curl -fLsS "$url" -o "$stage/archive.tar.gz"
    tar -xOzf "$stage/archive.tar.gz" "$archive/glow" > "$stage/glow"
    if [ ! -s "$stage/glow" ]; then
        echo_error "Glow archive contains an empty binary"
        return 1
    fi
    install -m 0755 "$stage/glow" "$stage/installed-glow"
    mv -f -- "$stage/installed-glow" "$GLOW_INSTALL_DIR/glow"
    echo_info "Installed Glow to $GLOW_INSTALL_DIR/glow"
)

parse_command "install:0 remove:0" "$@"
case "$1" in
    install) install_glow ;;
    remove) rm -f -- "$GLOW_INSTALL_DIR/glow" ;;
esac
