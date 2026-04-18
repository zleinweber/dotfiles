# TODO

This file turns the repository review into concrete implementation work.

The intent for this repository is:

- personal-first rather than framework-first
- reliable support for active environments on macOS and GitHub Codespaces
- generic Linux support as an intended target, even if it is not exercised regularly yet
- `./setup` should be safe to rerun unattended after any necessary initial sudo authentication

## Phase 1: Correctness and Safety

These are the highest-priority fixes because they affect whether `./setup` does the right thing at all.

- [x] Fix recipe selection in `setup`.
  - Auto-selection now chooses a valid recipe or exits with a clear error.
  - Covered paths:
    - macOS
    - Codespaces
    - generic Linux
- [x] Make missing or unreadable recipes fatal.
  - `setup` now exits when the requested recipe cannot be loaded.
- [x] Fix the APT remove-path bug.
  - When `APT_REMOVE_PACKAGES` is set, `setup` now passes `APT_REMOVE_PACKAGES[@]`, not `APT_INSTALL_PACKAGES[@]`.
- Fix boolean handling in `setup`.
  - [x] `SETUP_ATUIN=false` must not run the Atuin installer.
  - Audit every `SETUP_*` and related control flag for consistent behavior.
- Standardize boolean evaluation.
  - Introduce a helper such as `is_true`.
  - Use it everywhere instead of mixing command-style booleans and string checks.

## Phase 2: Unattended and Idempotent Execution

These changes are aimed at making `./setup` reliably unattended and safe to rerun.

- Add fail-fast shell behavior where practical.
  - Use `set -euo pipefail` in `setup` and helper scripts.
  - Where failures are intentionally tolerated, handle them explicitly and locally.
- Review every script for idempotence.
  - Re-running `./setup` should not produce harmful side effects.
  - Re-running after a partial failure should converge cleanly.
- Tighten sudo handling.
  - For platforms that require a password, authenticate once and reuse the credential cache.
  - For environments with passwordless sudo, keep the run fully unattended.
- Review installer scripts that depend on `curl | bash` or `wget | sh`.
  - Confirm they are safe to rerun.
  - Where possible, prefer more explicit installation paths or stronger checks around existing installs.

## Phase 3: Atuin Cleanup

The current Atuin approach is one of the least reliable parts of the repo and should be simplified.

- Remove login behavior from shell startup.
  - `.zshrc` initialization should not perform `atuin login`.
- Keep shell startup limited to shell integration.
  - `atuin init zsh` is appropriate.
  - Authentication and sync bootstrap should be separate from interactive shell startup.
- Redesign the install flow in `scripts/atuin.sh`.
  - Stop trying to restore repo files after the third-party installer runs.
  - If the upstream installer mutates user shell config, either avoid that path or isolate it safely.
- Decide what "configured Atuin" means for this repo.
  - Installed only
  - Installed plus shell integration
  - Installed plus optional explicit login step

## Phase 4: Generic Linux Support

Generic Linux is intended, but it is not a regularly exercised path today. That means the implementation should be made explicit and conservative.

- Define what "generic Linux" means in this repo.
  - Debian/Ubuntu only
  - APT-based systems only
  - any Linux with conditional package-manager support
- Add a first explicit Linux recipe if needed.
  - If Codespaces is too special-purpose, create a separate generic Linux recipe instead of overloading the Codespaces one.
- Ensure the auto-selection logic matches actual supported platforms.
  - Unsupported platforms should fail clearly rather than partially proceeding.
- Document the support level honestly.
  - "Intended but not regularly exercised" is better than implying full support.

## Phase 5: Validation and Maintenance Guardrails

These tasks reduce the chance of regressions.

- Add static validation for shell scripts.
  - `bash -n`
  - `shellcheck`
- Add lightweight smoke tests.
  - Validate recipe loading.
  - Validate the setup decision tree.
  - Validate boolean flag behavior.
- Consider adding CI for script validation.
  - Even a minimal CI check would catch several current issues.

## Phase 6: Documentation Alignment

The repo documentation should reflect what the code actually guarantees.

- Update `README.md` to match real platform support.
- Document unattended execution expectations.
  - Explain when sudo may be required.
  - Explain that the goal is unattended completion after initial authentication if needed.
- Keep `REVIEW.md` as the higher-level assessment.
- Use this file for concrete implementation work items.

## Phase 7: Optional Cleanup

These are lower-priority improvements that may help later.

- Review personal identity in tracked Git config.
  - This is acceptable for a personal-first repo.
  - If future reuse becomes important, move personal identity and signing details into a local include.
- Clean up small shell quality issues.
  - typo-like names such as `ZDOTIFLE`
  - quoting consistency
  - minor README drift and wording issues

## Recommended Order of Execution

1. Standardize boolean handling.
2. Add fail-fast shell behavior.
3. Rework Atuin to remove shell-start authentication behavior.
4. Define and implement the generic Linux story explicitly.
5. Add validation tooling and lightweight CI.
6. Refresh docs to match the new guarantees.
