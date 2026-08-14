## Context

See `proposal.md` for motivation. The repository already has a weekly full-lock workflow, cross-system CI, deterministic OMP package checks, activation verification, and generation rollback. The updater uses the default workflow token, whose pull requests do not start normal CI without human intervention. The remote main branch has no protection or ruleset.

The personal OMP package pins a separately released plugin. Runtime changes therefore cross two repository gates: plugin publication first, then workstation pin update and activation.

## Goals / Non-Goals

**Goals:**

- Make every automated update create a normally tested, review-only pull request.
- Enforce Darwin and Linux checks before merge for every actor.
- Detect OpenSpec package and generated-adapter skew.
- Provide one durable operating procedure for update, activation, smoke, and rollback.
- End permanent ambiguity around untracked planning documents.

**Non-Goals:**

- Automatic merge or workstation activation.
- A model-backed smoke in unattended CI.
- Mutation, backup, or restoration of OMP-owned state.
- Renovate Nix input updates.
- A custom workstation update command.

## Decisions

### Preserve the existing full-lock workflow

Keep `DeterminateSystems/update-flake-lock` as the weekly owner of every direct workstation input. Continue to create one atomic pull request because the configured generation and cross-system checks validate the input set as a composition. Preserve `workflow_dispatch` for an immediate run.

Splitting the lock by input was rejected. It adds branch and scheduling coordination without isolating the resulting system build.

### Authenticate with the shared dependency-updater App

Use the same private GitHub App as the plugin repository. Install it only on `nix-config` and `omp-agent-setup`; grant metadata read, contents read/write, and pull requests read/write. Store the client ID as a repository Actions variable and the private key as a repository Actions secret. Mint one installation token per workflow run through a commit-pinned `actions/create-github-app-token` action and pass it to the flake updater.

The installation token causes pull-request events to start normal CI and expires automatically. A personal access token and the default workflow token were rejected because the former is long-lived and human-owned and the latter does not provide the required unattended CI behavior.

### Keep Renovate outside Nix

Add `renovate.json` extending the shared `glockyco/renovate-config`. Let Renovate update GitHub Action pins. Set `nix.enabled=false` explicitly. Do not add a second lock-maintenance rule.

### Enforce the workflow's actual job contexts

Protect `main` with exact contexts `check (macos-15)` and `check (ubuntu-latest)`. Require a strict, up-to-date branch and linear history. Disallow force-push and deletion. Enforce the rule for administrators. This single-maintainer repository does not require an approval count, but all merges still pass through a pull request and checks.

Prefer classic branch protection because the plugin repository already uses it and the required-status behavior is sufficient. A repository-local policy file was rejected because it cannot enforce GitHub merges.

### Compare OpenSpec at both package boundaries

Expose the selected OpenSpec package in the Home Manager package set so its executable and metadata share one derivation. Replace any fixed version assertion with a check that compares `openspec --version` against `openspec.version`.

Select the llm-agents revision that provides OpenSpec 1.9 without changing the OMP 17.2.15 or Herdr 0.8.0 package versions. Add a pure freshness check that copies the flake source to a writable temporary directory, runs the selected `openspec update`, and compares tracked `.omp/commands` and `.omp/skills`. Set the CI and telemetry opt-out environment variables so generation is noninteractive and performs no version probe. The check reports drift but never rewrites the checkout during evaluation or activation.

Use strict active-contract validation and OpenSpec 1.9's `validate --archived` mode in a second check. This catches scenario loss, invalid task numbering, and incomplete archived work without a custom parser.

### Keep activation and smoke deliberate

CI proves evaluation and deterministic package contracts. After merge, a maintainer runs the native `nix flake check`, build, `darwin-switch`, activation verifier, and inspection commands. If the change affects `llm-agents`, the personal plugin, or wrapper behavior, the maintainer runs the real wrapped OMP session described by the architecture document. Keep the prior Nix generation until all applicable gates pass.

### Make operations discoverable without another wrapper

Add a short root `AGENTS.md` that points to the architecture, update runbook, active OpenSpec change, and release gates. Add `docs/operations/dependency-updates.md` with the ownership table, schedules, native commands, expected CI contexts, App credential rotation, activation, smoke, and rollback.

Classify every existing `docs/plans/` file in its index. Commit retained historical plans, move live implementation work into OpenSpec, and remove only documents confirmed obsolete by their content. This changes ownership, not their historical claims.

## Risks / Trade-offs

- The GitHub App private key becomes a repository secret in two places. Its installation scope and permissions minimize impact; the runbook requires rotation after exposure or owner change.
- A full lock update can combine unrelated inputs. Human review and both platform checks remain mandatory; maintainers can close the pull request and update a single input manually when diagnosis requires isolation.
- OpenSpec regeneration can be nondeterministic if upstream introduces remote inputs. The selected release currently operates on local templates; the check will fail rather than allow silent network-dependent drift.
- Enforced administrator protection removes direct pushes. This is intentional. Workstation rollback does not depend on GitHub availability.
