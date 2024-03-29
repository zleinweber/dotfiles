#!/usr/bin/env bash

## stow.sh ##
#
# Script to specified dotfile packages using GNU Stow
#

## Globals ##
STOW_DIR="${STOW_DIR:-./stow}"
STOW_TARGET_DIR="${STOW_TARGET_DIR:-$HOME}"
STOW_CONFLICT="${STOW_CONFLICT:-backup}"
STOW_CONFLICTS_DIR="${STOW_CONFLICTS_DIR:-$HOME/.stow_conflicts}"

## Functions ##
function usage () {
    echo "Usage: $0 install <package...>"
    echo ""
    echo "Commands:"
    echo "  install - Install specified package(s)"
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
        file_rel_path="${package_file#$package_path/}"
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
        echo "WARNING: package not found '$package'"
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
        check_for_required_deps stow find
        manage_conflicts "$@"
        install "$@"
        ;;
    *)
        echo "ERROR: Invalid command '$command'"
        usage
        exit 1
        ;;
esac
