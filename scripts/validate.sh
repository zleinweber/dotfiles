#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname -- "${BASH_SOURCE[0]}")/.."
for file in setup scripts/*.sh recipes/* tests/*.sh; do
    bash -n "$file"
done
if command -v shellcheck >/dev/null 2>&1; then
    shellcheck -x scripts/*.sh recipes/* setup tests/*.sh
else
    echo 'shellcheck is required for validation' >&2
    exit 1
fi
bash tests/scripts.sh
bash tests/neovim.sh
bash tests/codex.sh
