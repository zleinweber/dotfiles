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

function source_recipe () {
    local recipe_name="$1"
    local recipe_path="${RECIPE_DIR}/${recipe_name}"

    if [ -r "$recipe_path" ]; then
        echo_info "Loading recipe '$recipe_name'"

        # shellcheck source=/dev/null
        source "$recipe_path"
    else
        echo_error "Recipe '$recipe_name' does not exist or is not readable"
    fi
}

function sudo_up_front () {
    # Useful primarily for macos where we have to sudo with password
    if [ "$(id -u)" -ne 0 ]; then
        echo_info "Requesting sudo password to cache credentials for script run duration"
        sudo -v
        while true; do
            sudo -n true
            sleep 60
            kill -0 "$$" || exit
        done 2>/dev/null &
    else
        echo_info "Already running as root"
    fi
}
