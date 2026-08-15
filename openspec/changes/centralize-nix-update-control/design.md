## Context

See `proposal.md` for motivation. The App has one installation across selected repositories, so every copy of its private key can mint tokens for every repository in that installation. GitHub has no account-level Actions secret for personal repositories. This repository already has fail-closed Darwin and Linux CI, a protected main branch, and a Renovate rule that reserves Nix inputs.

## Goals / Non-Goals

**Goals:**

- Keep one App private key in one protected control-plane repository.
- Preserve repository-scoped installation tokens and normal target pull-request CI.
- Keep complete Nix updates, manual activation, and rollback explicit.

**Non-Goals:**

- Centralize target CI, merge decisions, activation, or rollback.
- Give Renovate ownership of Nix inputs.
- Add a custom dependency command wrapper.

## Decisions

### Use one protected control plane

`glockyco/dependency-automation` stores the App key, schedule, and managed-repository registry. One matrix job mints a token restricted to `nix-config`, runs `nix flake update`, and permits only `flake.lock` to change.

Keeping the local workflow was rejected because it would retain one fleet-wide private key in every target. Creating one App per repository was rejected because App and key rotation overhead would grow with the fleet. The controller limits the credential trust root without changing target ownership.

### Keep validation and activation local

The controller creates a review-only App-authored pull request. `nix-config` continues to run its normal Darwin and Linux checks. Merging remains separate from `darwin-switch`, the real OMP smoke, and generation rollback.

Moving CI or activation into the controller was rejected because platform behavior and mutable workstation state belong to this repository and machine. Dispatching CI separately was rejected because it loses pull-request event semantics.

### Preserve the native update command

The controller stores `nix flake update` as an argument array and fails if it changes a path outside the `flake.lock` allowlist.

A target-local wrapper was rejected because the complete scheduled update needs no post-update command. Manual targeted OMP and OpenSpec updates retain their documented regeneration commands.

## Risks / Trade-offs

- [The controller becomes a privileged dependency] → Protect its main branch, pin Actions, and require its validation check.
- [The controller registry and target policy can drift] → Keep Renovate's Nix manager disabled locally and require a targeted live run for every registry change.
- [A complete lock update needs generated adapters] → Let target CI fail closed and repair the updater branch with the documented native regeneration command.
- [A central outage pauses Nix updates] → Keep the manual `nix flake update` path. Activation and rollback do not depend on the controller.

## Migration Plan

1. Publish and protect `glockyco/dependency-automation`.
1. Configure the App key only in the controller.
1. Run a targeted workstation update and verify App authorship plus normal target CI.
1. Remove the local updater workflow, variable, and secret.
1. Close the obsolete updater branch and pull request.

Rollback restores the target-local workflow and its App configuration from the previous revision. Manual updates remain available throughout migration.
