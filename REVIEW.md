# Repository Review

This document captures the current review of the repository, the highest-priority fixes, and the recommended follow-up work to make the repo more robust.

This review was generated using openai codex with minimal human input.

## Summary

The repository is not fundamentally flawed. The overall structure is sensible:

- `setup` is the entrypoint.
- `recipes/` select a platform/scenario.
- `scripts/` encapsulate setup tasks.
- `stow/` contains the dotfile payload.

The main issue is not the architecture. It is execution quality. The repo has a good shape for a personal bootstrap system, but it does not yet fully meet its stated goals of simplicity, idempotence, and multi-platform safety.

## Intended Scope

The current intent is:

- personal-first rather than framework-first
- support real, active environments on macOS and GitHub Codespaces
- keep generic Linux as an intended target, even though it is not currently exercised regularly
- require `./setup` to be safe for unattended reruns after any necessary initial sudo authentication

This framing matters for evaluation. Some portability concerns are less important for a strictly personal repo, but unattended safety and repeatability are more important.

## Findings

### 1. Fixed: recipe auto-selection could leave setup in an undefined state on non-Codespaces Linux

References:

- [`setup:15`](./setup)
- [`setup:24`](./setup)
- [`scripts/common.sh:27`](./scripts/common.sh)

Status:

- fixed in the working tree

`setup` now selects an explicit generic Linux recipe when `CODESPACES=false`, fails explicitly on unknown platforms, and exits immediately when the selected recipe cannot be sourced. That closes the original undefined-state failure mode.

### 2. Fixed: APT package removal was wired to the wrong array

References:

- [`setup:88`](./setup)

Status:

- fixed in the working tree

The remove branch now checks `APT_REMOVE_PACKAGES` and passes `APT_REMOVE_PACKAGES[@]` to `scripts/apt.sh remove`.

### 3. High: `SETUP_ATUIN=false` still executes the Atuin installer

References:

- [`setup:104`](./setup)
- [`recipes/default:19`](./recipes/default)
- [`recipes/macosx:19`](./recipes/macosx)

The condition uses `[ -n "${SETUP_ATUIN}" ]`, which is true for both `"true"` and `"false"`. That makes the recipe flag ineffective and causes behavior that contradicts the recipe definitions.

### 4. Medium: recipe-level control for auto-selection is dead code or misnamed

References:

- [`setup:8`](./setup)
- [`recipes/default:9`](./recipes/default)

`setup` reads `SETUP_AUTOCHOOSE_RECIPE`, but recipes define `AUTOCHOOSE_PLATFORM_RECIPE`. As written, the recipe cannot influence that behavior. This is a maintainability bug and a sign the contract between `setup` and recipes has drifted.

### 5. Medium: the bootstrap does not fail fast

References:

- [`setup:3`](./setup)
- [`scripts/apt.sh:227`](./scripts/apt.sh)
- [`scripts/homebrew.sh:26`](./scripts/homebrew.sh)

The scripts generally omit `set -e` and `set -o pipefail`. For a machine bootstrap repo, that is a significant reliability issue: one failed command can be followed by many succeeding commands, leaving the machine in a half-configured state with no strong signal.

### 6. Medium: the Atuin installer workaround is conceptually wrong and operationally brittle

References:

- [`scripts/atuin.sh:30`](./scripts/atuin.sh)
- [`scripts/atuin.sh:41`](./scripts/atuin.sh)

The script diffs and restores `stow/zsh/.zshrc` in the repo, but the third-party installer would mutate the user's actual shell config, not the repo copy. So the "restore" logic is pointed at the wrong file. Even if it happens to work in one environment, it is not a sound idempotence strategy.

### 7. Medium: Atuin login in shell startup is an inadvisable pattern

References:

- [`stow/atuin/.zshrc.d/10_atuin.zsh:4`](./stow/atuin/.zshrc.d/10_atuin.zsh)

Running `atuin login` during shell initialization couples interactive shell startup to credential presence and networked auth state. That is surprising behavior for `.zshrc` and can create slow or noisy shells. Login/bootstrap should be a one-time setup step, not a shell-start side effect.

### 8. Medium: the macOS Git config bakes in personal identity and workstation-specific signing assumptions

References:

- [`stow/gitconfig-osx/.gitconfig:7`](./stow/gitconfig-osx/.gitconfig)
- [`stow/gitconfig-osx/.gitconfig:15`](./stow/gitconfig-osx/.gitconfig)

This is less severe for a strictly personal repo than it would be in a shared framework. Even so, hardcoded name, email, SSH signing key, and 1Password app path still reduce portability and make future generic reuse harder.

### 9. Low: the zsh bootstrap has a typo and weak quoting

References:

- [`stow/zsh/.zshrc:14`](./stow/zsh/.zshrc)

`ZDOTIFLE` is presumably meant to be `ZDOTFILE` or similar. It works because the same typo is used consistently, but it is an avoidable paper cut. The file also uses unquoted variable expansions in places where quoting would be safer.

### 10. Low: README overstates current support and is slightly out of sync with behavior

References:

- [`README.md:7`](./README.md)
- [`README.md:57`](./README.md)

The README promises simple, idempotent, multi-platform setup, including Arch as future support, but the implementation currently has correctness gaps in the supported paths and no Arch implementation at all. The design intent is clear; the docs are just a bit ahead of the code.

## Priority Order

1. Fix boolean handling, starting with `SETUP_ATUIN`, then standardize all booleans.
2. Add fail-fast shell options and error handling across `setup` and helper scripts.
3. Remove Atuin auth/login from shell startup and redesign its install flow.
4. Separate personal identity, secrets, and machine-local settings from reusable tracked config.
5. Tighten docs to match actual guarantees.

## Recommended First Changes

### 1. Make recipe selection explicit and total

Status:

- completed in the working tree

In `setup`:

- support macOS
- support Codespaces
- either support generic Linux or exit with a clear error
- exit immediately if no recipe is selected or readable

### 2. Standardize boolean handling

Introduce a helper such as `is_true "${VAR:-false}"` and use it consistently for:

- every `SETUP_*` toggle
- package-manager upgrade/cleanup flags
- any other env-driven control flow

### 3. Add strict shell mode

Use strict mode where practical:

- `set -euo pipefail`

If a script intentionally tolerates a failure, that should be explicit and local rather than implicit across the whole script.

### 4. Add lightweight validation

At minimum:

- `bash -n` for all scripts
- `shellcheck`
- a smoke test that validates recipe wiring and the `setup` decision tree

Even basic automated checks would catch several of the current issues.

### 5. Rework Atuin integration

Recommended direction:

- install the binary/tool only
- keep shell init to `atuin init zsh`
- move login and sync setup to an explicit one-time command rather than shell startup

### 6. Split reusable config from personal identity

Recommended direction:

- keep general Git behavior in tracked config
- move personal name, email, signing key, and workstation-specific signing program into a local include or separate machine-local config

## Overall Assessment

The repository does not need a redesign. The structure is good enough to keep. The main work is tightening the contract between recipes and `setup`, making failure explicit, and removing a few brittle patterns. If those are addressed, this should become a solid personal bootstrap repo rather than a mostly-working one.

Given the intended scope, the most important standard is not "can this be a reusable framework for anyone?" but "does this reliably rebuild the author's environments without supervision?" By that standard, the current structure is appropriate, but the implementation still needs hardening in a few key places.
