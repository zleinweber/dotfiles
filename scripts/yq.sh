#!/usr/bin/env bash

## Globals ##
YQ_BINARY="${YQ_BINARY:-yq_linux_amd64}"
YQ_VERSION="${YQ_VERSION:-v4.45.1}"
YQ_INSTALL_DIR="${YQ_INSTALL_DIR:-/usr/local/bin}"

## Functions ##
source ./scripts/common.sh

function usage () {
    echo "Usage: $0 {install|remove} | help"
    echo ""
    echo "Install yq from the latest binary release tarball."
    echo "The primary use case is for installing this on linux64 systems."
    echo ""
    echo "Commands:"
    echo "  install - Install yq"
    echo "  remove  - Remove yq"
    echo "  help    - Display this help message"
}

function install () {
    local yq_version="$1"
    local yq_binary="$2"
    local yq_install_dir="$3"
    local yq_download_url="https://github.com/mikefarah/yq/releases/download/${yq_version}/${yq_binary}.tar.gz"

    wget "$yq_download_url" -O - | sudo tar -C "$yq_install_dir" -xz \
        && sudo mv "${yq_install_dir}/${yq_binary}" "${yq_install_dir}/yq" \
        && sudo chmod 0775 "${yq_install_dir}/yq"
}

function remove_yq () {
    local yq_install_dir="$1"

    sudo rm -f "${yq_install_dir}/yq"
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
        install "$YQ_VERSION" "$YQ_BINARY" "$YQ_INSTALL_DIR"
        ;;
    remove)
        remove_yq "$YQ_INSTALL_DIR"
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
