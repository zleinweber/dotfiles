#!/usr/bin/env bash

VERBOSITY="${VERBOSITY:-3}"

function echo_timestamp () {
    date +"%Y-%m-%d %H:%M:%S"
}

function echo_info () {
    if [ "$VERBOSITY" -ge 3 ]; then
        echo "$(echo_timestamp) [INFO] $*" 1>&2
    fi
}

function echo_warn () {
    if [ "$VERBOSITY" -ge 2 ]; then
        echo "$(echo_timestamp) [WARN] $*" 1>&2
    fi
}

function echo_error () {
    if [ "$VERBOSITY" -ge 1 ]; then
        echo "$(echo_timestamp) [ERROR] $*" 1>&2
    fi
}

function detect_platform () {
    case "$(uname -s)" in
        Darwin)
            echo "darwin"
            ;;
        Linux)
            echo "linux"
            ;;
        *)
            echo_error "Unsupported platform: $(uname -s)"
            return 1
            ;;
    esac
}

function detect_arch () {
    case "$(uname -m)" in
        x86_64|amd64)
            echo "x86_64"
            ;;
        aarch64|arm64)
            echo "arm64"
            ;;
        *)
            echo_error "Unsupported architecture: $(uname -m)"
            return 1
            ;;
    esac
}

function source_recipe () {
    local recipe_name="$1"
    local recipe_path="${RECIPE_DIR}/${recipe_name}"

    if [ -r "$recipe_path" ]; then
        # shellcheck source=/dev/null
        source "$recipe_path"
    else
        return 1
    fi
}

function sudo_up_front () {
    # Useful primarily for MacOSX where we have to sudo with password
    if [ "$(id -u)" -ne 0 ]; then
        sudo -v
        while true; do
            sudo -n true
            sleep 60
            kill -0 "$$" || exit
        done 2>/dev/null &
    fi
}
