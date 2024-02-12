export HOMEBREW_PREFIX="/opt/homebrew";
export HOMEBREW_CELLAR="/opt/homebrew/Cellar";
export HOMEBREW_REPOSITORY="/opt/homebrew";
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin${PATH+:$PATH}";
export MANPATH="/opt/homebrew/share/man${MANPATH+:$MANPATH}:";
export INFOPATH="/opt/homebrew/share/info:${INFOPATH:-}";
export HOMEBREW_NO_ANALYTICS="1";

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
