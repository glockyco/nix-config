# Design

## Context

See `proposal.md`. The official plugin was evaluated in OMP 18.10.4 on 2026-10-31. `omp plugin upgrade` updates only marketplace plugins, so an npm plugin stays at the version it was installed with.

## Goals / Non-Goals

**Goals:**

- Reproducible plugin versions on both hosts and sharing off.

**Non-Goals:**

- Automating the plugin installation. Plugins are installed by documented commands, like the other OMP plugins.
- Changing the plugin's agent tool or feedback text. Both stay as Plannotator ships them.

## Decisions

### Merge one key instead of owning the file

Plannotator's settings page writes `~/.plannotator/config.json`. A chezmoi modify template reads the current file, sets `share` to `disabled` and writes everything else back, so chezmoi and the settings page do not fight.

### Pin the plugin in the documented install command

The README holds the one install command with its version. The Korolev runbook refers to it. Advancing it is part of the Plannotator update steps.

## Risks / Trade-offs

- A review left open across `/new` sends its feedback to the new session. Reviewers send or close a review before switching.
- About 370 MB per host for the plugin and its Pi packages.
