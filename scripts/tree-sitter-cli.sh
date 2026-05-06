#!/usr/bin/env bash

set -o pipefail

## Globals ##
TREE_SITTER_CLI_VERSION="${TREE_SITTER_CLI_VERSION:-latest}"
TREE_SITTER_CLI_INSTALL_DIR="${TREE_SITTER_CLI_INSTALL_DIR:-/usr/local/bin}"
TREE_SITTER_CLI_FORCE_INSTALL="${TREE_SITTER_CLI_FORCE_INSTALL:-true}"

## Functions ##
source ./scripts/common.sh

function usage () {
    echo "Usage: $0 {install|remove} | help"
    echo ""
    echo "Install tree-sitter CLI from the GitHub release zip."
    echo "Supports Linux x86_64/amd64 and arm64/aarch64 systems."
    echo ""
    echo "Environment:"
    echo "  TREE_SITTER_CLI_VERSION       Release version to install, or latest (default: latest)"
    echo "  TREE_SITTER_CLI_INSTALL_DIR   Directory for tree-sitter binary (default: /usr/local/bin)"
    echo "  TREE_SITTER_CLI_FORCE_INSTALL Reinstall when tree-sitter already exists (default: true)"
    echo ""
    echo "Commands:"
    echo "  install - Install tree-sitter CLI"
    echo "  remove  - Remove tree-sitter CLI"
    echo "  help    - Display this help message"
}

function check_tree_sitter_cli_dependencies () {
    if ! command -v unzip > /dev/null 2>&1; then
        echo_error "unzip is required to install tree-sitter CLI"
        return 1
    fi
}

function check_supported_platform () {
    local platform="$1"
    local arch="$2"

    if [ "$platform" != "linux" ]; then
        echo_error "Unsupported tree-sitter CLI platform: $platform"
        return 1
    fi

    case "$arch" in
        x86_64|arm64)
            ;;
        *)
            echo_error "Unsupported tree-sitter CLI architecture: $arch"
            return 1
            ;;
    esac
}

function tree_sitter_cli_asset_arch () {
    local arch="$1"

    case "$arch" in
        x86_64)
            echo "x64"
            ;;
        arm64)
            echo "arm64"
            ;;
        *)
            echo_error "Unsupported tree-sitter CLI asset architecture: $arch"
            return 1
            ;;
    esac
}

function tree_sitter_cli_download_url () {
    local tree_sitter_cli_version="$1"
    local platform="$2"
    local asset_arch="$3"
    local asset_name="tree-sitter-cli-${platform}-${asset_arch}.zip"

    if [ "$tree_sitter_cli_version" = "latest" ]; then
        echo "https://github.com/tree-sitter/tree-sitter/releases/latest/download/${asset_name}"
    else
        echo "https://github.com/tree-sitter/tree-sitter/releases/download/${tree_sitter_cli_version}/${asset_name}"
    fi
}

function check_if_tree_sitter_cli_installed () {
    local tree_sitter_cli_install_dir="$1"

    if [ -x "${tree_sitter_cli_install_dir}/tree-sitter" ]; then
        return 0
    else
        return 1
    fi
}

function install_tree_sitter_cli () {
    local tree_sitter_cli_version="$1"
    local tree_sitter_cli_install_dir="$2"
    local platform
    local arch
    local asset_arch
    local download_url
    local tmp_dir
    local zip_file

    check_tree_sitter_cli_dependencies || exit 1

    platform="$(detect_platform)" || exit 1
    arch="$(detect_arch)" || exit 1
    check_supported_platform "$platform" "$arch" || exit 1

    if check_if_tree_sitter_cli_installed "$tree_sitter_cli_install_dir"; then
        echo_info "tree-sitter CLI is already installed"
        if "$TREE_SITTER_CLI_FORCE_INSTALL"; then
            echo_info "Forcing re-installation"
        else
            exit 0
        fi
    fi

    asset_arch="$(tree_sitter_cli_asset_arch "$arch")" || exit 1
    download_url="$(tree_sitter_cli_download_url "$tree_sitter_cli_version" "$platform" "$asset_arch")"
    tmp_dir="$(mktemp -d -t tree-sitter-cli-XXXXXXXXXX)"
    zip_file="${tmp_dir}/tree-sitter-cli.zip"

    echo_info "Installing tree-sitter CLI ${tree_sitter_cli_version} from ${download_url}"
    if ! curl -fLsS "$download_url" -o "$zip_file"; then
        rm -rf "$tmp_dir"
        return 1
    fi

    if ! unzip -q "$zip_file" -d "$tmp_dir"; then
        rm -rf "$tmp_dir"
        return 1
    fi

    if ! sudo install -m 0775 "${tmp_dir}/tree-sitter" "${tree_sitter_cli_install_dir}/tree-sitter"; then
        rm -rf "$tmp_dir"
        return 1
    fi

    rm -rf "$tmp_dir"
}

function remove_tree_sitter_cli () {
    local tree_sitter_cli_install_dir="$1"

    sudo rm -f "${tree_sitter_cli_install_dir}/tree-sitter"
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
        install_tree_sitter_cli "$TREE_SITTER_CLI_VERSION" "$TREE_SITTER_CLI_INSTALL_DIR"
        ;;
    remove)
        remove_tree_sitter_cli "$TREE_SITTER_CLI_INSTALL_DIR"
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
