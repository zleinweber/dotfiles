# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

# Standard ZSH history
HISTFILE=$HOME/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
HIST_STAMPS="yyyy-mm-dd"

# atuin history
if command -v atuin > /dev/null 2>&1; then
    eval "$(atuin init zsh)"
fi

ZSH_CUSTOM=$HOME/.oh-my-zsh/custom

ZDOTIFLE=$HOME/.zshrc.d
for file in $ZDOTIFLE/*.zsh; do
    source $file
done

source $ZSH/oh-my-zsh.sh
