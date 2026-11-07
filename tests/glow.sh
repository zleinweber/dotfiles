#!/usr/bin/env bash
# Test platform assets and failed updates using real archives in a disposable directory.
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
fixture=$(mktemp -d)
trap 'rm -rf "$fixture"' EXIT
mkdir -p "$fixture/bin" "$fixture/archive"
export GLOW_INSTALL_DIR="$fixture/install with spaces"
export GLOW_FORCE_INSTALL=false GLOW_VERSION=latest
export GLOW_TEST_ARCHIVE="$fixture/archive.tar.gz" GLOW_TEST_LOG="$fixture/url"
cat > "$fixture/bin/curl" <<'MOCK'
#!/usr/bin/env bash
if [ "${GLOW_TEST_FAIL:-false}" = true ]; then exit 22; fi
if [ "$2" = -o ]; then
    printf 'https://github.com/charmbracelet/glow/releases/tag/v3.0.0'
else
    printf '%s\n' "$2" > "$GLOW_TEST_LOG"
    cp "$GLOW_TEST_ARCHIVE" "$4"
fi
MOCK
cat > "$fixture/bin/uname" <<'MOCK'
#!/usr/bin/env bash
case "$1" in
    -s) echo "$GLOW_TEST_OS" ;;
    -m) echo "$GLOW_TEST_ARCH" ;;
    *) exit 1 ;;
esac
MOCK
chmod +x "$fixture/bin/"*
export PATH="$fixture/bin:$PATH"
cd "$fixture"

for pair in 'Linux x86_64 Linux_x86_64' 'Linux aarch64 Linux_arm64' \
    'Darwin x86_64 Darwin_x86_64' 'Darwin arm64 Darwin_arm64'; do
    read -r GLOW_TEST_OS GLOW_TEST_ARCH target <<< "$pair"
    export GLOW_TEST_OS GLOW_TEST_ARCH
    archive="glow_3.0.0_$target"
    mkdir -p "$fixture/archive/$archive"
    printf '#!/bin/sh\necho fixture-v1\n' > "$fixture/archive/$archive/glow"
    tar -czf "$GLOW_TEST_ARCHIVE" -C "$fixture/archive" "$archive/glow"
    bash "$root/scripts/glow.sh" install
    [[ "$("$GLOW_INSTALL_DIR/glow")" == fixture-v1 ]]
    [[ "$(cat "$GLOW_TEST_LOG")" == "https://github.com/charmbracelet/glow/releases/download/v3.0.0/$archive.tar.gz" ]]
    bash "$root/scripts/glow.sh" remove
done

for version in 3.0.0 v3.0.0; do
    GLOW_VERSION="$version" bash "$root/scripts/glow.sh" install
    bash "$root/scripts/glow.sh" remove
done
bash "$root/scripts/glow.sh" install
export GLOW_TEST_FAIL=true
# A repeat install skips network access; a failed forced update preserves glow.
bash "$root/scripts/glow.sh" install
export GLOW_FORCE_INSTALL=true
if bash "$root/scripts/glow.sh" install >/dev/null 2>&1; then exit 1; fi
export GLOW_TEST_FAIL=false
printf 'not an archive' > "$GLOW_TEST_ARCHIVE"
if bash "$root/scripts/glow.sh" install >/dev/null 2>&1; then exit 1; fi
[[ "$("$GLOW_INSTALL_DIR/glow")" == fixture-v1 ]]
[[ -z "$(find "$GLOW_INSTALL_DIR" -name '.glow-download.*' -print)" ]]

export GLOW_TEST_ARCH=riscv64
if bash "$root/scripts/glow.sh" install >/dev/null 2>&1; then exit 1; fi
export GLOW_TEST_ARCH=x86_64 GLOW_TEST_OS=FreeBSD
if bash "$root/scripts/glow.sh" install >/dev/null 2>&1; then exit 1; fi
bash "$root/scripts/glow.sh" remove
bash "$root/scripts/glow.sh" remove
echo 'Glow binary installation checks passed'
