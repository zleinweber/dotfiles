#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

## Functions ##
source ./scripts/common.sh

function usage () {
    echo "Usage: $0 configure|fd|shell|help"
    echo ""
    echo "Configure GitHub Codespaces system settings."
    echo ""
    echo "Commands:"
    echo "  configure - Configure all Codespaces system settings"
    echo "  fd        - Link fd to fdfind when fd-find is installed via apt"
    echo "  shell     - Set the Codespaces user's login shell to zsh"
    echo "  help      - Display this help message"
}

function configure_login_shell () {
    local user="${CODESPACES_USER:-${USER:-codespace}}"
    local zsh_path
    local current_shell

    zsh_path="$(command -v zsh)"
    if [ -z "$zsh_path" ]; then
        echo_error "Unable to find zsh in PATH"
        return 1
    fi

    current_shell="$(getent passwd "$user" | cut -d: -f7)"
    if [ -z "$current_shell" ]; then
        echo_error "Unable to determine login shell for user '$user'"
        return 1
    fi

    if [ "$current_shell" = "$zsh_path" ]; then
        echo_info "Login shell for '$user' is already '$zsh_path'"
        return 0
    fi

    echo_info "Setting login shell for '$user' to '$zsh_path'"
    sudo chsh -s "$zsh_path" "$user"
}

function configure_fd_command () {
    local fd_path="$HOME/.local/bin/fd"
    local fdfind_path

    if command -v fd >/dev/null 2>&1; then
        echo_info "fd command already available"
        return 0
    fi

    fdfind_path="$(command -v fdfind || true)"
    if [ -z "$fdfind_path" ]; then
        echo_warn "Unable to configure fd command because fdfind is not available"
        return 0
    fi

    mkdir -p "$HOME/.local/bin"

    if [ -L "$fd_path" ] && [ "$(readlink "$fd_path")" = "$fdfind_path" ]; then
        echo_info "fd symlink already configured"
        return 0
    fi

    if [ -e "$fd_path" ]; then
        echo_warn "Not replacing existing fd at $fd_path"
        return 0
    fi

    echo_info "Linking fd to $fdfind_path"
    ln -s "$fdfind_path" "$fd_path"
}

function configure_codespaces_system () {
    configure_login_shell
    configure_fd_command
}

## Main ##
command="${1:-}"
if [ "$#" -gt 0 ]; then
    shift
fi

if [ -z "$command" ]; then
    echo_error "Missing argument 'command'"
    usage
    exit 1
fi

case $command in
    configure)
        configure_codespaces_system
        ;;
    fd)
        configure_fd_command
        ;;
    shell)
        configure_login_shell
        ;;
    help)
        usage
        ;;
    *)
        echo_error "Invalid command '$command'"
        usage
        exit 1
        ;;
esac
