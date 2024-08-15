# dotfiles

Yet another dotfiles repository.

## Goals

- Low touch. Platform should be automatically detected and configured and require as litle human input as possible.
- Idempotent. It should always be safe to run the whole setup script from the top.
- Modularity. It should be possible to build 'recipes' by mixing and matching different modules.

## Features

### Generic features

- Configuration files are grouped into 'packages' and managed via stow
  - Supports automatically backing up any existing conflicts for a managed file.
- Installation of third party tools and utilities via the appropriate package manager
  - APT on Ubuntu
  - Brew on MacOSX
  - Pacman on Arch (future support)
- Conifguration of MacOSX system settings in a scripted way

### Tool support

- atuin
- oh-my-zsh
- homebrew
- neovim

### Platform support

- macosx
- Ubuntu in codespaces
- Archlinux (future support)

## Structure

### ./setup

`./setup` is a shell script that requires no arguments and by default runs through all setup tasks for a platform. It serves as the main entrypoint to setup tasks. It is idempotent and can be run at any time.

It's primary job is to choose a _recipe_ either by taking a recipe passed in via an environment variable or by choosing an appropriate one based on the detected platform. It then runs through an executes the appropriate set of steps based on the settings in the recipe. Each step is typically encapsulated by a script in the `scripts/` directory.

### recipes/

A recipe is a configuration file for a given scenario, platform, etc. It's job is to inform `./setup` and the scripts that it calls in the `scripts/` dir how they should behave. It does this by setting environment variables that are used by `./setup` and the scripts in `scripts/`.

`./setup` should choose exactly one recipe and that recipe needs to, at minimum, configure all the environment variables for `./setup` to run.

The environment variables set in a recipe are used to inform things like:

- Control for third party tooling install scripts. These are typically used for tools that cannot be installed via a package manager (for example the homebrew package manager itself).
- The list of external packages to be installed via a package manager.
- The list of configuration packages to install via stow (these are the 'modular' packages local to this repository that contain dotfiles)

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
