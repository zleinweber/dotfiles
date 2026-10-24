#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=scripts/common.sh
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/common.sh"

## Globals ##
STOW_DIR="${STOW_DIR:-$DOTFILES_ROOT/stow}"
STOW_TARGET_DIR="${STOW_TARGET_DIR:-$HOME}"
STOW_CONFLICT="${STOW_CONFLICT:-backup}"
STOW_CONFLICTS_DIR="${STOW_CONFLICTS_DIR:-$HOME/.stow_conflicts}"

## Functions ##

function usage () {
    echo "Usage: $0 {install|remove} <package...> | help"
    echo ""
    echo "Manage stow packages"
    echo ""
    echo "Commands:"
    echo "  install - Install specified package(s)"
    echo "  remove  - Remove specified package(s)"
    echo "  help    - Display this help message"
}

check_for_required_deps () {
    local deps=("$@")
    for d in "${deps[@]}"; do
        if ! command -v "$d" &> /dev/null; then
            echo "ERROR: $d is not installed"
            exit 1
        fi
    done
}

function manage_package_conflicts () {
    local package="$1"
    local conflicts_dir="${STOW_CONFLICTS_DIR}/${package}"
    local package_path="${STOW_DIR}/${package}"

    find "$package_path" -mindepth 1 -type f | while read -r package_file; do
        file_rel_path="${package_file#"$package_path"/}"
        file_install_path="${STOW_TARGET_DIR}/${file_rel_path}"
        file_backup_path="${conflicts_dir}/${file_rel_path}"
        file_backup_dir=$(dirname "$file_backup_path")

        if [ -e "$file_install_path" ]; then
            file_install_realpath=$(realpath "$file_install_path")
            file_package_realpath=$(realpath "$package_file")

            if [ "$file_install_realpath" == "$file_package_realpath" ]; then
                echo "File already installed from stow package: $file_install_path"
                continue
            fi

            case "$STOW_CONFLICT" in
                backup)
                    echo "Backup conflict: '$file_install_path' -> '$file_backup_path'"
                    mkdir -p "$file_backup_dir"
                    mv "$file_install_path" "$file_backup_path"
                    ;;
                overwrite)
                    echo "Overwriting conflict: $file_install_path"
                    rm -f "$file_install_path"
                    ;;
                *)
                    echo "Skipping conflict: $file_install_path"
                    ;;
            esac
        fi
    done
}

function manage_conflicts () {
    local packages=("$@")
    for package in "${packages[@]}"; do
        manage_package_conflicts "$package"
    done
}

function install_package () {
    local package="$1"
    local package_path="${STOW_DIR}/${package}"

    if [ -d "$package_path" ]; then
        echo "Installing package: $package"
        stow --dir="$STOW_DIR" --target="$STOW_TARGET_DIR" "$package"
    else
        echo_error "Package not found: $package"
        return 1
    fi
}

function install () {
    local packages=("$@")
    for package in "${packages[@]}"; do
        install_package "$package"
    done
}

## Main ##
parse_command "install:1+ remove:1+" "$@"
command="${1:-help}"
if [ "$#" -gt 0 ]; then
    shift
fi

case $command in
    install)
        check_for_required_deps stow find
        for package in "$@"; do
            [ -d "$STOW_DIR/$package" ] || { echo_error "Package not found: $package"; exit 1; }
        done
        manage_conflicts "$@"
        install "$@"
        ;;
    remove)
        check_for_required_deps stow
        for package in "$@"; do
            echo "Removing package: $package"
            stow --dir="$STOW_DIR" --target="$STOW_TARGET_DIR" -D "$package"
        done
        ;;
    help)
        usage
        ;;
    *)
        echo "ERROR: Invalid command '$command'"
        usage
        exit 1
        ;;
esac
