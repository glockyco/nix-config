# Design

## Context

The memory backend is a setting in `~/.omp/agent/config.yml`, which the workstation preserves as mutable runtime state and never manages. The README and the Korolev runbook already set other OMP options with `omp config set` during installation.

## Goals / Non-Goals

**Goals:**

- Both hosts run OMP with memory off, and a reinstall from the documentation does the same.

**Non-Goals:**

- Deleting or migrating the existing banks.
- Managing `config.yml` through chezmoi.

## Decisions

### Set the option during installation

The option joins the `omp config set` line for ignored skills in both install blocks, because `config.yml` stays mutable and OMP writes to it. A chezmoi template would make it a second owner of a file OMP edits.

### Drop the bank porting from the spec

The porting scenario requires that a fresh session finds ported decisions, which cannot hold with memory off. The litellm definition and the list of state never imported stay, with memory banks added to that list.

## Risks / Trade-offs

- [Risk] A session no longer recalls a decision that only a bank held. Mitigation: decisions go into the project's repository or the notes vault, where sessions read them.
