#!/usr/bin/env bash
# Real tar and Stow operations in a disposable home, with no network or sudo.
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
fixture=$(mktemp -d)
trap 'rm -rf "$fixture"' EXIT
export HOME="$fixture/home with spaces"
export NVIM_DIST=nvim-linux-x86_64
export NVIM_TARBALL_URL=https://example.invalid/neovim.tar.gz
export NVIM_FORCE_INSTALL=false
unset NVIM_INSTALL_DIR NVIM_STOW_DIR
mkdir -p "$HOME" "$fixture/bin" "$fixture/archive/$NVIM_DIST/bin" \
    "$fixture/archive/$NVIM_DIST/share/nvim/runtime" "$fixture/archive/$NVIM_DIST/lib/nvim/parser"
printf '#!/bin/sh\necho fixture-v1\n' > "$fixture/archive/$NVIM_DIST/bin/nvim"
chmod +x "$fixture/archive/$NVIM_DIST/bin/nvim"
echo runtime > "$fixture/archive/$NVIM_DIST/share/nvim/runtime/file"
echo parser > "$fixture/archive/$NVIM_DIST/lib/nvim/parser/test.so"
export NVIM_TEST_ARCHIVE="$fixture/neovim.tar.gz"
tar -czf "$NVIM_TEST_ARCHIVE" -C "$fixture/archive" "$NVIM_DIST"
cat > "$fixture/bin/curl" <<'MOCK'
#!/usr/bin/env bash
if [ "${NVIM_TEST_FAIL_DOWNLOAD:-false}" = true ]; then exit 22; fi
cat "$NVIM_TEST_ARCHIVE"
MOCK
cat > "$fixture/bin/sudo" <<'MOCK'
#!/usr/bin/env bash
echo 'Neovim installer must not use sudo' >&2
exit 99
MOCK
chmod +x "$fixture/bin/"*
export PATH="$fixture/bin:$PATH"
cd "$fixture"

bash "$root/scripts/neovim.sh" install
[[ "$("$HOME/.local/bin/nvim")" == fixture-v1 ]]
[[ -f "$HOME/.local/share/nvim/runtime/file" ]]
[[ -f "$HOME/.local/lib/nvim/parser/test.so" ]]

# Reruns need no download and repair missing links.
export NVIM_TEST_FAIL_DOWNLOAD=true
rm "$HOME/.local/bin/nvim"
bash "$root/scripts/neovim.sh" install
[[ "$("$HOME/.local/bin/nvim")" == fixture-v1 ]]

# A failed update leaves the working installation intact and cleans staging.
export NVIM_FORCE_INSTALL=true
if bash "$root/scripts/neovim.sh" install >/dev/null 2>&1; then
    echo 'Failed download unexpectedly succeeded' >&2
    exit 1
fi
[[ "$("$HOME/.local/bin/nvim")" == fixture-v1 ]]
[[ -z "$(find "$HOME/.local/stow" -name '.nvim-download.*' -print)" ]]

# An incomplete archive also preserves the installed version.
export NVIM_TEST_FAIL_DOWNLOAD=false
mkdir "$fixture/empty"
tar -czf "$NVIM_TEST_ARCHIVE" -C "$fixture/empty" .
if bash "$root/scripts/neovim.sh" install >/dev/null 2>&1; then
    echo 'Incomplete archive unexpectedly succeeded' >&2
    exit 1
fi
[[ "$("$HOME/.local/bin/nvim")" == fixture-v1 ]]

printf '#!/bin/sh\necho fixture-v2\n' > "$fixture/archive/$NVIM_DIST/bin/nvim"
tar -czf "$NVIM_TEST_ARCHIVE" -C "$fixture/archive" "$NVIM_DIST"
bash "$root/scripts/neovim.sh" install
[[ "$("$HOME/.local/bin/nvim")" == fixture-v2 ]]

# Removal leaves unrelated files intact and can be repeated.
echo keep > "$HOME/.local/bin/unrelated"
bash "$root/scripts/neovim.sh" remove
bash "$root/scripts/neovim.sh" remove
[[ ! -e "$HOME/.local/stow/$NVIM_DIST" ]]
[[ ! -L "$HOME/.local/bin/nvim" ]]
[[ "$(cat "$HOME/.local/bin/unrelated")" == keep ]]

# A conflicting user file is never overwritten; retry can finish linking.
echo original > "$HOME/.local/bin/nvim"
if bash "$root/scripts/neovim.sh" install >/dev/null 2>&1; then
    echo 'Conflicting file was not rejected' >&2
    exit 1
fi
[[ "$(cat "$HOME/.local/bin/nvim")" == original ]]
rm "$HOME/.local/bin/nvim"
export NVIM_FORCE_INSTALL=false NVIM_TEST_FAIL_DOWNLOAD=true
bash "$root/scripts/neovim.sh" install
[[ "$("$HOME/.local/bin/nvim")" == fixture-v2 ]]
bash "$root/scripts/neovim.sh" remove

# Custom writable prefixes work without elevated permissions.
export NVIM_TEST_FAIL_DOWNLOAD=false
export NVIM_INSTALL_DIR="$fixture/custom packages" NVIM_STOW_DIR="$fixture/custom prefix"
bash "$root/scripts/neovim.sh" install
[[ "$("$NVIM_STOW_DIR/bin/nvim")" == fixture-v2 ]]
bash "$root/scripts/neovim.sh" remove

# Distribution overrides cannot escape the package directory.
if NVIM_DIST=../escape bash "$root/scripts/neovim.sh" remove >/dev/null 2>&1; then
    echo 'Unsafe distribution name was not rejected' >&2
    exit 1
fi
echo 'Neovim install, update, conflict, and removal checks passed'
