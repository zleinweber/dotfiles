# atuin history
if command -v atuin > /dev/null 2>&1; then
    eval "$(atuin init zsh)"
    if [ -n "${ATUIN_USERNAME}" ] && [ -n "${ATUIN_PASSWORD}" ] && [ -n "${ATUIN_KEY}" ]; then
        atuin login --username "${ATUIN_USERNAME}" --password "${ATUIN_PASSWORD}" --key "${ATUIN_KEY}"
    fi

    if [ -n "${ZSH_LOCAL_COMPLETIONS}" ]; then
        mkdir -p "${ZSH_LOCAL_COMPLETIONS}"
        if ! [ -f "${ZSH_LOCAL_COMPLETIONS}/_atuin" ]; then
            atuin gen-completions --shell zsh --out-dir "${ZSH_LOCAL_COMPLETIONS}"
        fi
    fi
fi
