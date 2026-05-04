#!/usr/bin/env bash

## Functions ##
source ./scripts/common.sh

FABRIC_URL_BASE="https://github.com/danielmiessler/fabric/releases/latest/download"
FABRIC_BIN_PATH="$HOME/.local/bin/fabric"

function usage () {
    echo "Usage: $0 install|help"
    echo ""
    echo "Install fabric (see also https://github.com/danielmiessler/fabric)"
    echo ""
    echo "Commands:"
    echo "  install - Install fabric"
    echo "  help    - Display this help message"
}

function fabric_is_installed () {
    if [ -x "$FABRIC_BIN_PATH" ]; then
        return 0
    else
        return 1
    fi
}

function get_fabric_url () {
    local -n url=$1

    os_type="$(uname -s)"
    os_arch="$(uname -m)"

    case "$os_type" in
        Darwin)
            if [ "$os_arch" == "x86_64" ]; then
                url="$FABRIC_URL_BASE/fabric-darwin-amd64"
            else
                url="$FABRIC_URL_BASE/fabric-darwin-amd64"
            fi
        ;;
        Linux)
            if [ "$os_arch" == "x86_64" ]; then
                url="$FABRIC_URL_BASE/fabric-linux-amd64"
            else
                url="$FABRIC_URL_BASE/fabric-linux-arm64"
            fi
        ;;
        *) echo_error "Unsupported OS: $os_type"; exit 1 ;;
    esac

}

function install () {
    if fabric_is_installed; then
        echo_info "fabric is already installed"
    else
        declare fabric_url
        get_fabric_url fabric_url

        echo_info "Downloading fabric from $fabric_url"
        curl -s -L -o "$FABRIC_BIN_PATH" "$fabric_url" && chmod +x "$FABRIC_BIN_PATH"
    fi
}

## Main ##
command="$1"

case $command in
    install)
        install
        ;;
    help)
        usage
        ;;
    *)
        echo_error "Invalid command '$command'"
        usage
        exit 1
esac
