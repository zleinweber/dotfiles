#!/usr/bin/env bash
# Exercise real tar/file operations without network, npm, or system writes.
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
fixture=$(mktemp -d)
trap 'rm -rf "$fixture"' EXIT
export HOME="$fixture/home with spaces"
export CODEX_FORCE_INSTALL=false
unset CODEX_INSTALL_DIR CODEX_TARBALL_URL
export CODEX_TEST_ARCHIVE="$fixture/codex.tar.gz" CODEX_TEST_LOG="$fixture/url"
mkdir -p "$fixture/bin" "$fixture/archive" "$HOME"
cat > "$fixture/bin/curl" <<'MOCK'
#!/usr/bin/env bash
printf '%s\n' "$2" > "$CODEX_TEST_LOG"
if [ "${CODEX_TEST_FAIL:-false}" = true ]; then exit 22; fi
cp "$CODEX_TEST_ARCHIVE" "$4"
MOCK
cat > "$fixture/bin/uname" <<'MOCK'
#!/usr/bin/env bash
case "$1" in
    -s) echo "$CODEX_TEST_OS" ;;
    -m) echo "$CODEX_TEST_ARCH" ;;
    *) exit 1 ;;
esac
MOCK
for cmd in npm sudo; do
    printf '#!/bin/sh\nexit 99\n' > "$fixture/bin/$cmd"
done
chmod +x "$fixture/bin/"*
# Exclude unrelated developer installations of codex from the test PATH.
export PATH="$fixture/bin:/usr/bin:/bin"
cd "$fixture"

make_archive () {
    local binary="$1" version="$2"
    printf '#!/bin/sh\necho %s\n' "$version" > "$fixture/archive/$binary"
    tar -czf "$CODEX_TEST_ARCHIVE" -C "$fixture/archive" "$binary"
}

for pair in 'Linux x86_64 x86_64-unknown-linux-musl' 'Linux aarch64 aarch64-unknown-linux-musl' \
    'Darwin x86_64 x86_64-apple-darwin' 'Darwin arm64 aarch64-apple-darwin'; do
    read -r CODEX_TEST_OS CODEX_TEST_ARCH target <<< "$pair"
    export CODEX_TEST_OS CODEX_TEST_ARCH
    make_archive "codex-$target" fixture-v1
    bash "$root/scripts/codex.sh" install
    [[ "$("$HOME/.local/bin/codex")" == fixture-v1 ]]
    [[ "$(cat "$CODEX_TEST_LOG")" == "https://github.com/openai/codex/releases/latest/download/codex-$target.tar.gz" ]]
    rm "$HOME/.local/bin/codex"
done

export CODEX_TEST_OS=Linux CODEX_TEST_ARCH=x86_64
binary=codex-x86_64-unknown-linux-musl
make_archive "$binary" fixture-v1
bash "$root/scripts/codex.sh" install
export CODEX_TEST_FAIL=true
# Skip the configured destination even if it is not on PATH.
bash "$root/scripts/codex.sh" install
export CODEX_FORCE_INSTALL=true
if bash "$root/scripts/codex.sh" install >/dev/null 2>&1; then exit 1; fi
[[ "$("$HOME/.local/bin/codex")" == fixture-v1 ]]
export CODEX_TEST_FAIL=false

# Corrupt, wrong-platform, and empty archives preserve the installed executable.
printf 'not a tarball' > "$CODEX_TEST_ARCHIVE"
if bash "$root/scripts/codex.sh" install >/dev/null 2>&1; then exit 1; fi
make_archive wrong-name fixture-v2
if bash "$root/scripts/codex.sh" install >/dev/null 2>&1; then exit 1; fi
: > "$fixture/archive/$binary"
tar -czf "$CODEX_TEST_ARCHIVE" -C "$fixture/archive" "$binary"
if bash "$root/scripts/codex.sh" install >/dev/null 2>&1; then exit 1; fi
[[ "$("$HOME/.local/bin/codex")" == fixture-v1 ]]
[[ -z "$(find "$HOME/.local/bin" -name '.codex-download.*' -print)" ]]

make_archive "$binary" fixture-v2
export CODEX_TARBALL_URL=https://example.invalid/pinned-codex.tar.gz
bash "$root/scripts/codex.sh" install
[[ "$("$HOME/.local/bin/codex")" == fixture-v2 ]]
[[ "$(cat "$CODEX_TEST_LOG")" == "$CODEX_TARBALL_URL" ]]

# Force replacement replaces the link, not an existing binary it points to.
mv "$HOME/.local/bin/codex" "$fixture/other-codex"
ln -s "$fixture/other-codex" "$HOME/.local/bin/codex"
make_archive "$binary" fixture-v3
bash "$root/scripts/codex.sh" install
[[ ! -L "$HOME/.local/bin/codex" ]]
[[ "$("$fixture/other-codex")" == fixture-v2 ]]
[[ "$("$HOME/.local/bin/codex")" == fixture-v3 ]]

export CODEX_INSTALL_DIR="$fixture/custom prefix"
bash "$root/scripts/codex.sh" install
[[ "$("$CODEX_INSTALL_DIR/codex")" == fixture-v3 ]]
rm "$CODEX_INSTALL_DIR/codex"
mkdir "$CODEX_INSTALL_DIR/codex"
if bash "$root/scripts/codex.sh" install >/dev/null 2>&1; then exit 1; fi
[[ ! -e "$CODEX_INSTALL_DIR/codex/codex" ]]

# Existing PATH installs keep working without npm or downloads.
cp "$fixture/other-codex" "$fixture/bin/codex"
export CODEX_FORCE_INSTALL=false CODEX_TEST_FAIL=true
bash "$root/scripts/codex.sh" install
rm "$fixture/bin/codex"
export CODEX_TEST_ARCH=riscv64
if bash "$root/scripts/codex.sh" install >/dev/null 2>&1; then exit 1; fi
export CODEX_TEST_ARCH=x86_64 CODEX_TEST_OS=FreeBSD
if bash "$root/scripts/codex.sh" install >/dev/null 2>&1; then exit 1; fi
echo 'Codex standalone installation checks passed'
