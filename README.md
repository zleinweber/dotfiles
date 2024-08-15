# dotfiles

My dotfiles repository. These files are tailored to my opinions and personal preferences.

## Goals

- Low touch. Environment should be automatically detected and configured and require as litle human input as possible.
- Idempotent. It should always be safe to run the whole setup script from the top.
- Modularity. It should be possible to build 'recipes' by mixing and matching different modules.

## Features

### Generic features

- Configuration files are grouped into 'packages' and managed via stow
  - Supports automatically backing up any existing conflicts for a managed file.
- Installation of third party tools and utilities via the appropriate package manager
  - APT on Ubuntu
  - Brew on MacOSX
  - Pacman on Arch
- Conifguration of MacOSX system settings in a scripted way

### Tool support

- atuin
- oh-my-zsh
- homebrew
- neovim

## Structure

### recipes/

The desired configuration will depend on the target platform that we are configuring. As a result, most of the scripts here are configurable in the form of environment variables. These variables control things like:

- The list of external packages to be installed
- The appropriate package manager to use to install pacakges (Apt, Pacman, Brew)
- The list of stow packages to install (these are the 'modular' packages local to this repository that contain dotfiles)
- Control for third party tooling install scripts that can't be installed via a package manager (oh-my-zsh, atuin, homebrew, etc.)

Recipes are a pre-set configuration of all of these environment variables intended as the 'default' for a desired platform. This allows for fully automated configuration as, in most cases, it is trivial to automatically detect the platform we are running on and dynamically load the appropriate recipe. These `recipes` live in the `recipes` directory and are auto-loaded by the `setup` script.

### scripts/

A directory that contains `scripts` that do specific things. For example, the `scripts/homebrew.sh` script can be used to install the homebrew package manager. Each of these scripts should take one or more sub-commands (e.g. `scripts/homebrew.sh install`). Omitting a sub-command should cause the script to output some usage information. For example:

```text
Usage: ./scripts/homebrew.sh install|bundle

Commands:
  install - Install homebrew if it's not already installed
  bundle - Install packages from a Brewfile bundle
```

Further, these scripts should be as idempotent as possible. Taking `scripts/homebrew.sh install` as an example, it should first check if `homebrew` is already installed. If it is it should do nothing.

Nomrally, these scripts are not called directly by the user. Rather these scripts are called as appropriate when running the `setup` script depending on the environment variables cnofigured in the recipe.

### stow/

This is, perhaps, the most important directory in this repository as it contains the actual dotfiles to be installed. Each top level directory under `./stow/` is a 'stow package' that can be installed using the `scripts/stow.sh intall <package_name>` command. Each stow package contains one or more dotfiles in a directory tree that should mirror that of the users home directory. For example, if we have a `atuin` stow package that has the following files in it (relative to the root of this repo):

- `./stow/atuin/.config/atuin/config.toml`
- `./stow/atuin/.zshrc.d/atuin.zsh`

Then these files will get installed in the following locations by default when installing the 'stow package':

- `$HOME/.config/atuin/config.toml`
- `$HOME/.zshrc.d/atuin.zsh`

## Usage

### Main Entrypoint - ./setup

The `./setup` is the main entrypoint. It's primary purpose is to dynamically detect the environment and load the appropriate recipe. Once this is done it calls the relevant scripts in the `scripts` directory in sequence to set everything up. This script should be safe to run at anytime. This means that it and any scripts that it calls should be idempotent.

To use in codespaces you need to configure this as your 'dotfiles' repository in user settings. Once done this repo will automatically be cloned into your codespace and the `./setup` script will get called automatically during the provisioning process.

### Calling Scripts Directly

It is also possible to call scripts in the `scripts/` directory directly. Each of these scripts should output help information if no sub-command is passed in.
