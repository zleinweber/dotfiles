#!/usr/bin/env bash

## stow.sh ##
#
# Script to specified dotfile packages using GNU Stow
#

## Globals ##
STOW_DIR="${STOW_DIR:-./stow}"
STOW_TARGET_DIR="${STOW_TARGET_DIR:-$HOME}"

## Functions ##
function usage () {
    echo "Usage: $0 <package>..."
    echo ""
    echo "Commands:"
    echo "  install - Install specified package(s)"
}

function install_package () {
    local package="$1"
    local package_path="${STOW_DIR}/${package}"

    if [ -d "$package_path" ]; then
        echo "Installing package: $package"
        stow --dir="$STOW_DIR" --target="$STOW_TARGET_DIR" "$package"
    else
        echo "ERROR: package not found '$package'"
    fi
}

function install () {
    local packages=("$@")
    for package in "${packages[@]}"; do
        install_package "$package"
    done
}

## Main ##
command="$1"

if [ -z "$command" ]; then
    echo "ERROR: Missing argument 'command'"
    usage
    exit 1
fi

case $command in
    install)
        shift
        install "$@"
        ;;
    *)
        echo "ERROR: Invalid command '$command'"
        usage
        exit 1
        ;;
esac
