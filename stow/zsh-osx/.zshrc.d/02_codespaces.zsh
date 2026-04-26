
cslist() {
  gh codespace list
}

csconf() {
  local tmp

  mkdir -p ~/.ssh
  tmp="$(mktemp ~/.ssh/codespaces.XXXXXX)" || return

  if gh codespace ssh --config > "$tmp"; then
    mv "$tmp" ~/.ssh/codespaces
  else
    rm -f "$tmp"
    return 1
  fi
}

cssh() {
  local target="$1"

  csconf || return

  if [[ -z "$target" ]]; then
    target="$(
      grep '^Host ' ~/.ssh/codespaces |
        awk '{print $2}' |
        fzf --prompt='codespace> '
    )"
  fi

  [[ -n "$target" ]] || return 1
  kitten ssh "$target"
}

csdelete() {
  gh codespace delete "$@" && csconf
}
