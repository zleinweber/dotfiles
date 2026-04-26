
cslist() {
  gh codespace list
}

csconf() {
  mkdir -p ~/.ssh
  gh codespace ssh --config > ~/.ssh/codespaces
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
  gh codespace delete "$@"
  csconf
}
