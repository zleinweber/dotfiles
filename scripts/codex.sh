#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=scripts/common.sh
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/common.sh"

CODEX_INSTALL_DIR="${CODEX_INSTALL_DIR:-$HOME/.local/bin}"
CODEX_FORCE_INSTALL="${CODEX_FORCE_INSTALL:-false}"

function usage () {
    echo "Usage: $0 install|help"
    echo ""
    echo "Install the Codex standalone binary (Linux/macOS, x86_64/arm64)."
    echo ""
    echo "Commands:"
    echo "  install - Install codex without Node, npm, or sudo"
    echo "  help    - Display this help message"
    echo ""
    echo "Configuration:"
    echo "  CODEX_INSTALL_DIR   Writable binary directory (default: ~/.local/bin)"
    echo "  CODEX_FORCE_INSTALL Reinstall/update when true (default: false)"
    echo "  CODEX_TARBALL_URL   Override the platform archive URL (default: latest GitHub release)"
    echo "Put CODEX_INSTALL_DIR on PATH to run codex."
}

function install_codex () (
    local platform arch target binary url stage

    if ! is_true "$CODEX_FORCE_INSTALL"; then
        if { [ -f "$CODEX_INSTALL_DIR/codex" ] && [ -x "$CODEX_INSTALL_DIR/codex" ]; } || command -v codex >/dev/null 2>&1; then
            echo_info "codex cli is already installed"
            return 0
        fi
    fi

    platform="$(detect_platform)"
    arch="$(detect_arch)"
    case "$arch" in
        x86_64) ;;
        arm64) arch=aarch64 ;;
    esac
    case "$platform" in
        linux) target="$arch-unknown-linux-musl" ;;
        darwin) target="$arch-apple-darwin" ;;
    esac
    binary="codex-$target"
    url="${CODEX_TARBALL_URL:-https://github.com/openai/codex/releases/latest/download/$binary.tar.gz}"

    # Never move a binary into a directory named codex, including a symlink to one.
    if [ -d "$CODEX_INSTALL_DIR/codex" ]; then
        echo_error "Codex destination is a directory: $CODEX_INSTALL_DIR/codex"
        return 1
    fi
    mkdir -p "$CODEX_INSTALL_DIR"
    stage=$(mktemp -d "$CODEX_INSTALL_DIR/.codex-download.XXXXXX")
    trap 'rm -rf -- "$stage"' EXIT

    echo_info "Installing standalone Codex for $target"
    curl -fLsS "$url" -o "$stage/archive.tar.gz"
    # Read only the expected archive member; do not unpack arbitrary paths.
    tar -xOzf "$stage/archive.tar.gz" "$binary" > "$stage/codex"
    if [ ! -s "$stage/codex" ]; then
        echo_error "Codex archive contains an empty binary"
        return 1
    fi
    chmod 0755 "$stage/codex"
    # Staging on the same filesystem preserves the old binary until download and
    # extraction succeed, and replacement does not follow existing file symlinks.
    mv -f -- "$stage/codex" "$CODEX_INSTALL_DIR/codex"
    echo_info "Installed Codex to $CODEX_INSTALL_DIR/codex"
)

parse_command "install:0" "$@"
case "$1" in
    install) install_codex ;;
esac
