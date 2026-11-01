ZSH_THEME="af-magic"

DISABLE_AUTO_UPDATE=true
DISABLE_UPDATE_PROMPT=true

plugins=(
    fzf
    git
    vi-mode
)

# Use this installation when no earlier directory provides atuin.
if [[ -d "$HOME/.atuin/bin" ]]; then
    path+=("$HOME/.atuin/bin")
fi
