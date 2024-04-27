#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

## Functions ##
source ./scripts/common.sh

function usage () {
    echo "Usage: $0 defautls|hostname|help"
    echo ""
    echo "Configure various MacOS System Settings in an attempt to automate as"
    echo "much of system set as possible. This is inspired by:"
    echo "  https://github.com/mathiasbynens/dotfiles/blob/master/.macos"
    echo ""
    echo "Commands:"
    echo "  defaults - Configure MacOS settings via 'defaults'"
    echo "  hostname - Set the macos hostname"
    echo "  help    - Display this help message"
}

fucntion set_hostname () {
    local hostname="$1"

    if [ -z "$hostname" ]; then
        echo_error "set_hostname: Missing argument 'hostname'"
        return 1
    fi

    local current_hostname
    local current_computername
    local current_localhostname
    local current_netbiosname

    current_hostname=$(scutil --get HostName)
    current_computername=$(scutil --get ComputerName)
    current_localhostname=$(scutil --get LocalHostName)
    current_netbiosname=$(defaults read /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName)

    if [ "$current_hostname" = "$hostname" ] && \
        [ "$current_computername" = "$hostname" ] && \
        [ "$current_localhostname" = "$hostname" ] && \
        [ "$current_netbiosname" = "$hostname" ]; then
            echo_info "Hostname is already set to '$hostname'"
            return 0
    fi

    echo_info "Setting hostname to '$hostname'"
    sudo scutil --set HostName "$hostname"
    sudo scutil --set ComputerName "$hostname"
    sudo scutil --set LocalHostName "$hostname"
    sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "$hostname"
}

## Main ##
command="$1"; shift

if [ -z "$command" ]; then
    echo_error "Missing argument 'command'"
    usage
    exit 1
fi

case $command in
    defaults)
        echo_info "NOT IMPLEMENTED: Configuring MacOS settings via 'defaults'"
        ;;
    hostname)
        echo_info "Setting hostname"
        set_hostname "$1"
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
