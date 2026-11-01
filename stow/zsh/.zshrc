# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

# Keep the first occurrence of each directory, including assignments to PATH.
typeset -U PATH path
typeset -U FPATH fpath

# Prefer user-installed programs over inherited commands; platform overrides follow.
path=("$HOME/.local/bin" "${path[@]}")
export PATH

HISTFILE=$HOME/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
HIST_STAMPS="yyyy-mm-dd"

export ZSH_LOCAL_COMPLETIONS="$HOME/.local/share/zsh/completions"
if [[ -d "$ZSH_LOCAL_COMPLETIONS" ]]; then
   fpath=("$ZSH_LOCAL_COMPLETIONS" "${fpath[@]}")
fi

ZDOTIFLE=$HOME/.zshrc.d
for file in $ZDOTIFLE/*.zsh; do
   source $file
done
