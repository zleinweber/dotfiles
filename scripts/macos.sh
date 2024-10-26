#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

## Functions ##
source ./scripts/common.sh

function usage () {
    echo "Usage: $0 defaults|hostname|help"
    echo ""
    echo "Configure various MacOS System Settings in an attempt to automate as"
    echo "much of system set as possible. This is inspired by:"
    echo "  https://github.com/mathiasbynens/dotfiles/blob/master/.macos"
    echo ""
    echo "Commands:"
    echo "  configure - Configure MacOS system settings"
    echo "  hostname - Set the macos hostname"
    echo "  help     - Display this help message"
}

function configure_macosx_system () {
    ## Global Settings and Appearence ##
    defaults write NSGlobalDomain AppleInterfaceStyleSwitchesAutomatically -bool true
    defaults write NSGlobalDomain AppleAquaColorVariant -int 1
    defaults write NSGlobalDomain AppleAccentColor -int 6
    defaults write NSGlobalDomain AppleHighlightColor -string "1.000000 0.749020 0.823529 Pink"
    defaults write NSGlobalDomain AppleShowScrollBars -string "WhenScrolling"
    defaults write NSGlobalDomain NSQuitAlwaysKeepsWindows -bool FALSE
    defaults write NSglobalDomain NSTableViewDefaultSizeMode -int 1
    defaults write NSGlobalDomain com.apple.swipescrolldirection -bool FALSE

    ## Dock Settings ##
    defaults write com.apple.dock autohide -bool TRUE
    defaults write com.apple.dock orientation -string "left"
    defaults write com.apple.dock tilesize -int 36

    ## Finder Settings ##
    defaults write NSGlobalDomain AppleShowAllExtensions -bool TRUE
    defaults write com.apple.finder ShowPathbar -bool TRUE
    defaults write com.apple.finder ShowStatusBar -bool TRUE
    defaults write com.apple.finder NewWindowTarget -string "PfHm"
    defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/"
    defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
    defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
    defaults write com.apple.finder _FXSortFoldersFirst -bool true
    defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
    defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
    defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

    ## Safari Settings ##
    # Enable the Develop menu and the Web Inspector in Safari
    defaults write com.apple.Safari IncludeDevelopMenu -bool true
    defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
    defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true
}

function set_hostname () {
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
    configure)
        configure_macosx_system
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
