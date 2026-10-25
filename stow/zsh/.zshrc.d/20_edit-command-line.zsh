# Edit the current command in an editor, then return to the prompt for review.
# Prefer Neovim when installed.
if (( $+commands[nvim] )); then
    zstyle :zle:edit-command-line editor nvim
fi

autoload -Uz edit-command-line
zle -N edit-command-line
# Both platform configs enable oh-my-zsh's vi-mode plugin.
bindkey -M viins '^X^E' edit-command-line
bindkey -M vicmd '^X^E' edit-command-line
bindkey -M emacs '^X^E' edit-command-line
