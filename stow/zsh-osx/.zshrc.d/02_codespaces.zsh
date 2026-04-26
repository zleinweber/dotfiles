cshelp() {
  cat <<'EOF'
Codespaces terminal workflow

Prerequisite:
  ~/.ssh/config should include:

    Include ~/.ssh/codespaces

Core commands:
  cscreate [gh codespace create args]
      Create a codespace, then refresh ~/.ssh/codespaces.

  cscreate --connect [gh codespace create args]
      Create a codespace, refresh SSH config, then connect with kitten ssh.

  csconf
      Regenerate ~/.ssh/codespaces using:
        gh codespace ssh --config > ~/.ssh/codespaces

  cssh [codespace]
      Refresh SSH config, then connect with kitten ssh.
      If no codespace is given, select one with fzf.

  cslogs [codespace] [gh codespace logs args]
      Show logs for a codespace.
      If no codespace is given, select one with fzf.

  cslist
      List codespaces.

  csdelete [gh codespace delete args]
      Delete a codespace, then refresh SSH config.

Typical flow:
  cscreate --connect --repo OWNER/REPO
  # work in the codespace
  csdelete

Notes:
  - ~/.ssh/codespaces is regenerated, not appended.
  - This prevents stale SSH config from growing indefinitely.
  - kitten ssh installs/uses kitty terminfo on the remote side.
  - gh still handles the GitHub Codespaces SSH plumbing.
EOF
}

cslist() {
  gh codespace list
}

cscreate() {
  local connect=0

  if [[ "$1" == "--connect" ]]; then
    connect=1
    shift
  fi

  gh codespace create "$@" || return

  csconf || return

  if (( connect )); then
    cssh
  fi
}

cslogs() {
  local target="$1"
  shift || true

  if [[ -z "$target" ]]; then
    csconf || return

    target="$(
      grep '^Host ' ~/.ssh/codespaces |
        awk '{print $2}' |
        fzf --prompt='codespace logs> '
    )"
  fi

  [[ -n "$target" ]] || return 1

  gh codespace logs --codespace "$target" "$@"
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

