# Script interface

Task modules in `scripts/` expose a command-line interface, not exported shell
functions. `setup` executes them as child processes. Keep implementation functions
private to each script; only `common.sh` is intended to be sourced. `validate.sh`
is a developer command with no subcommands, and recipes are sourced configuration.

## Public contract

- Use Bash (`#!/usr/bin/env bash`) with `set -euo pipefail`. Preserve compatibility
  with macOS Bash 3.2 (no associative arrays or newer Bash-only syntax).
- Support `help`, `-h`, `--help`, and no arguments: print usage to stdout and exit
  zero, without checking dependencies, detecting architecture, downloading, or
  modifying anything.
- Validate the command and its argument count before side effects. Unknown commands,
  missing operands, or extra operands print a diagnostic and usage to stderr and
  exit nonzero. Positional operands are command-specific; there are no global flags
  other than help.
- Use `install` for tool installation, `remove` when removal is supported, and
  `configure` for system configuration. Other actions should have descriptive names
  (`bundle`, `hostname`, `upgrade`, etc.). Not every module needs every command.
- Exit zero for success, including an already-satisfied request. Propagate failures;
  explicitly handle expected failures locally. Do not wrap an entire operation in
  an `if`/`!` check that suppresses Bash's `errexit` inside its functions.
- Source `common.sh` relative to the script, so commands work from any working
  directory. Resolve repository-owned defaults with `DOTFILES_ROOT`; explicit
  relative path overrides are relative to the caller's directory. `setup` runs its
  tasks from the repository root.
- Accept configuration through environment variables named for the tool, with
  defaults using `${VAR:-default}`. Describe public overrides in usage or nearby
  documentation. Recipe assignments used by child scripts must be exported or
  passed explicitly; ordinary recipe variables only exist in `setup`.
- Use literal `true` and `false` for booleans and evaluate them with `is_true`.
  Invalid evaluated values fail rather than being executed as shell commands.
- Prefer convergence on reruns. Binary installers with `*_FORCE_INSTALL` default
  to `false`; explicitly set it to `true` to reinstall/update. Package-manager
  upgrades remain explicit commands. This does not pin upstream versions.
- Use `echo_info`, `echo_warn`, and `echo_error` for diagnostics (stderr), controlled
  by `VERBOSITY` (0 silent, 1 errors, 2 warnings, 3 info; default 3). Reserve stdout
  for usage, returned values, and underlying command output.
- Check operation-specific dependencies after argument validation. Quote paths and
  operand arrays. Use `sudo` only for operations requiring elevated access.

## Minimal module

```bash
#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=scripts/common.sh
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/common.sh"

function usage () {
    echo "Usage: $0 install | help"
    echo "  install - Install example if missing"
}

function install_example () {
    if command -v example >/dev/null 2>&1; then
        echo_info "example is already installed"
        return 0
    fi
    # Check dependencies and install; failures must propagate.
}

parse_command "install:0" "$@"
command="$1"
shift
case "$command" in
    install) install_example ;;
esac
```

`parse_command` takes a quoted, space-separated list of `command:arity`
declarations followed by the original argument vector. `install:0` accepts no operands, `hostname:1` takes
exactly one, and `install:1+` takes one or more. It exits for help or invalid input,
so the dispatcher only sees valid operations.

`common.sh` also provides logging, platform/architecture detection, recipe loading,
and sudo credential caching. Sourcing it must not dispatch an operation or change
shell options in its caller.

## Validation

Run `./scripts/validate.sh` (or `just validate`) with ShellCheck installed. It checks
syntax for each script and recipe, runs ShellCheck, and executes
`tests/scripts.sh`. The interface tests run from outside the repository and do not
install packages or change system configuration. They do not validate upstream
installers or prove full platform idempotence; test those in disposable target
machines when changing installation behavior.

Validation also runs `tests/neovim.sh` with GNU Stow installed. It uses local
fixture archives and a temporary home to test installation, link repair, failed
downloads, replacement, conflicts, and removal without network access or sudo.

## Neovim installation

On Linux, `scripts/neovim.sh install` downloads the upstream archive into a
temporary staging directory and installs it under
`~/.local/stow/nvim-linux-<architecture>`. GNU Stow links its `bin`, `lib`, and
`share` contents into `~/.local`; the executable is `~/.local/bin/nvim`. No sudo
is used. The shared Zsh configuration puts `~/.local/bin` first on PATH; other
shells need the same PATH entry.

Rerunning install repairs missing links without downloading again. Set
`NVIM_FORCE_INSTALL=true` to fetch and replace the package. Downloads must finish
and contain the executable and runtime before replacing an existing installation.
This is not a fully transactional upgrade: a subsequent filesystem or Stow failure
can still require rerunning install. `remove` unlinks the package and deletes its
installation directory, leaving unrelated files alone.

`NVIM_INSTALL_DIR` and `NVIM_STOW_DIR` can select other writable package and
target directories. Existing `/opt` installations are not migrated or deleted
automatically. After verifying the new user installation, an old default system
installation can be explicitly removed with:

```sh
sudo env NVIM_INSTALL_DIR=/opt NVIM_STOW_DIR=/usr/local ./scripts/neovim.sh remove
```

Use the old `NVIM_DIST` override too if that installation used a nondefault
distribution name. Do not run the whole setup as root. Open a new Zsh session
after updating the shell configuration, or add `~/.local/bin` to the current PATH.

## Codex installation

`scripts/codex.sh install` downloads the standalone Codex binary from the latest
official GitHub release and installs it as `~/.local/bin/codex`, without Node,
npm, or sudo. It selects the Linux musl or macOS archive for x86_64 or arm64.
The shared Zsh configuration already includes `~/.local/bin` on PATH.

An executable at the destination or a `codex` command already on PATH is left
alone by default. Set `CODEX_FORCE_INSTALL=true` to download again and replace
the configured destination. Other installations elsewhere on PATH are not
removed. `CODEX_INSTALL_DIR` overrides the writable destination directory, and
`CODEX_TARBALL_URL` can select a pinned release URL or a mirror containing the
expected platform-specific archive member.

Downloads and extraction complete in a temporary directory on the destination
filesystem before the executable is atomically replaced. Failures preserve the
existing executable and clean up staging files. Downloads use HTTPS with curl's
normal TLS verification; this installer does not independently verify release
checksums or signatures. The default latest-release URL is not version-pinned.

Validation runs `tests/codex.sh` with local fixture archives to cover platform
selection, reruns, overrides, failed downloads, corrupt/incomplete archives,
replacement, and conflicting destinations without running npm or sudo.
