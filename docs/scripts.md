# Script contract

Task scripts in `scripts/` expose a command-line interface and run as child
processes of `setup`. Their functions are private; only `common.sh` is intended
to be sourced. `validate.sh` is a developer command without subcommands.
Read each script for its commands, configuration, and behavior.

## Command-line interface

- Use `#!/usr/bin/env bash` and `set -euo pipefail`; stay compatible with macOS
  Bash 3.2.
- With no arguments, `help`, `-h`, or `--help`, print usage to stdout and exit
  zero without checking dependencies or performing operations.
- Validate commands and operand counts before side effects. Invalid input prints
  a diagnostic and usage to stderr and exits nonzero. Use `parse_command` from
  `common.sh` with `command:arity` declarations (`0`, `1`, or `1+`, for example).
  There are no global flags other than help.
- Name installation, removal, and configuration commands `install`, `remove`,
  and `configure` where supported. Give other actions descriptive names.
- Exit zero for success, including an already-satisfied request. Propagate
  failures and handle expected failures locally. Avoid wrapping an entire
  operation in `if` or `!`, which suppresses Bash's `errexit` within functions.

## Configuration and execution

- Source `common.sh` relative to the script so invocation works from any working
  directory. Use `DOTFILES_ROOT` for repository-owned defaults; resolve explicit
  relative path overrides from the caller's directory. `setup` runs tasks from
  the repository root.
- Accept configuration through tool-prefixed environment variables with
  `${VAR:-default}` defaults. Describe public overrides in the script's usage.
  Recipes must export variables needed by child scripts or pass them explicitly.
- Use literal `true` and `false` for booleans and evaluate them with `is_true`;
  invalid values fail.
- Make reruns converge on the requested state. Binary installers with
  `*_FORCE_INSTALL` default to `false`; setting it to `true` requests a reinstall
  or update. Keep package-manager upgrades explicit.
- Send diagnostics to stderr through `echo_info`, `echo_warn`, and `echo_error`.
  `VERBOSITY` controls logging: 0 silent, 1 errors, 2 warnings, 3 info (default).
  Reserve stdout for usage, returned values, and underlying command output.
- Check operation-specific dependencies after argument validation, quote paths
  and operand arrays, and use `sudo` only for operations requiring elevation.
- Keep `common.sh` safe to source: it must not dispatch operations or change the
  caller's shell options.

## Minimal example

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

`parse_command` exits for help or invalid input, so only valid operations reach
the dispatcher.

## Validation

Run `./scripts/validate.sh` (or `just validate`) to check shell syntax, ShellCheck,
and the test suite. Installation changes also need testing on disposable target
machines; interface checks alone do not establish platform support or idempotence.
