#!/usr/bin/env bash

set -euo pipefail

## Functions ##
# shellcheck source=scripts/common.sh
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/common.sh"

function usage () {
    echo "Usage: $0 configure|help"
    echo ""
    echo "Configure the hashi apt repo and keys"
    echo ""
    echo "Commands:"
    echo "  configure - Configure the hashi apt repo and keys"
    echo "  help      - Display this help message"
}

function check_if_repo_is_configured () {
    if [ -f /etc/apt/sources.list.d/hashicorp.list ]; then
        return 0
    else
        return 1
    fi
}

function configure () {
    if check_if_repo_is_configured; then
        echo_info "Hashi apt repo is already configured"
        return
    fi
    wget -O - https://apt.releases.hashicorp.com/gpg \
        | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
        | sudo tee /etc/apt/sources.list.d/hashicorp.list
}

## Main ##
parse_command "configure:0" "$@"
command="${1:-help}"
if [ "$#" -gt 0 ]; then
    shift
fi

case $command in
    configure)
        configure
        ;;
    help)
        usage
        ;;
    *)
        echo_error "Invalid command '$command'"
        usage
        exit 1
esac
