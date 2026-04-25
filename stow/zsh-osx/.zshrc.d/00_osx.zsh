export HOMEBREW_PREFIX="/opt/homebrew";
export HOMEBREW_CELLAR="/opt/homebrew/Cellar";
export HOMEBREW_REPOSITORY="/opt/homebrew";
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin${PATH+:$PATH}";
export MANPATH="/opt/homebrew/share/man${MANPATH+:$MANPATH}:";
export INFOPATH="/opt/homebrew/share/info:${INFOPATH:-}";
export HOMEBREW_NO_ANALYTICS="1";

# https://developer.1password.com/docs/ssh/get-started/#step-4-configure-your-ssh-or-git-client
export SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock

ZSH_THEME="robbyrussell"

DISABLE_AUTO_UPDATE=false
DISABLE_UPDATE_PROMPT=false

plugins=(
    brew
    git
    macos
    poetry
    vi-mode
)
