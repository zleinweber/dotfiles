#!/usr/bin/env bash
# Contract checks never execute an install/configure operation.
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd /tmp
for script in "$root"/scripts/*.sh; do
    case "$script" in */common.sh|*/validate.sh) continue ;; esac
    for help in '' help -h --help; do
        if [ -n "$help" ]; then
            output=$(bash "$script" "$help")
        else
            output=$(bash "$script")
        fi
        [[ "$output" == Usage:* ]]
    done
    for args in unknown 'help extra' 'install extra unexpected'; do
        read -r -a argv <<< "$args"
        # apt/stow accept package lists, so test their missing operands instead.
        case "$script:$args" in
            */apt.sh:install*|*/stow.sh:install*) argv=(install) ;;
        esac
        if bash "$script" "${argv[@]}" >/dev/null 2>&1; then
            echo "Unexpected success: $script ${argv[*]}" >&2
            exit 1
        fi
    done
done
# shellcheck source=scripts/common.sh
source "$root/scripts/common.sh"
is_true true
if is_true false; then exit 1; fi
if (is_true invalid) 2>/dev/null; then exit 1; fi
VERBOSITY=0
echo_info silent
echo_warn silent
echo_error silent
echo 'Script interface checks passed'

# A failed first operation must prevent the next operation, even in a function.
fixture=$(mktemp -d)
trap 'rm -rf "$fixture"' EXIT
mkdir "$fixture/bin"
cat > "$fixture/bin/sudo" <<'MOCK'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$CALL_LOG"
exit 42
MOCK
cat > "$fixture/bin/apt-get" <<'MOCK'
#!/usr/bin/env bash
exit 0
MOCK
chmod +x "$fixture/bin/"*
if CALL_LOG="$fixture/calls" PATH="$fixture/bin:$PATH" bash "$root/scripts/apt.sh" install example >/dev/null 2>&1; then
    echo 'APT failure was masked' >&2
    exit 1
fi
[[ "$(cat "$fixture/calls")" == 'apt-get update' ]]
# Existing binaries are skipped by default without downloading or using sudo.
for pair in 'lazygit LAZYGIT lazygit' 'ripgrep RIPGREP rg' 'tree-sitter-cli TREE_SITTER_CLI tree-sitter' 'yq YQ yq'; do
    read -r script prefix binary <<< "$pair"
    touch "$fixture/bin/$binary"
    chmod +x "$fixture/bin/$binary"
    env "${prefix}_INSTALL_DIR=$fixture/bin" bash "$root/scripts/$script.sh" install >/dev/null 2>&1
 done
echo 'Failure propagation and install skip checks passed'
