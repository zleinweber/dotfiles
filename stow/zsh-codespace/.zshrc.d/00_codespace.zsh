ZSH_THEME="devcontainers"

DISABLE_AUTO_UPDATE=true
DISABLE_UPDATE_PROMPT=true

plugins=(
    git
    vi-mode
)

if [ -d "$HOME/.atuin/bin" ]; then
    export PATH="$PATH:$HOME/.atuin/bin"
fi  
