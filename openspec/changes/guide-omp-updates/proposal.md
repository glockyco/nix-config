## Why

A fresh agent session cannot reliably complete an OMP update from the short command reference alone, especially when the maintained patches conflict. The repository needs discoverable guidance that carries an authorized update through runtime selection and verification, rather than stopping at a repaired branch or a list of commands.

## What Changes

- Add the authored repository-local skill `.agents/skills/omp-update/SKILL.md`, with explicit discovery metadata and concise, task-focused instructions.
- Enable the existing `mdformat-frontmatter` package in `treefmt.nix` so repository formatting preserves skill metadata without excluding skills.
- Extend `docs/operations/dependency-updates.md` with the detailed patch-refresh and update-completion procedure. Link it from the skill and the existing README update section without duplicating command ownership.
- Guide routine updates, unchanged releases, patch conflicts, other preparation failures, stale installed pins, and post-update recovery through the existing updater and verifier.
- Separate authorization for patch publication, configuration publication, host activation, and runtime selection. Default to the current supported host, not a fleet update.
- Require a fresh wrapped-session verification and the applicable release smoke before reporting success. Report unavailable credentials or approvals as blockers, not completed updates.
- Check Herdr prerequisites in the Bash command environment, preserve its control boundary, and complete independent checks when Herdr is unavailable.
- Verify real skill discovery and model use in fresh wrapped sessions, plus bounded rehearsals of the decision paths without publishing or activating production systems.

## Capabilities

### New Capabilities

- `omp-update-guidance`: Discoverable agent guidance for completing and verifying authorized personal OMP source updates, including patch maintenance and recovery.

### Modified Capabilities

None. This change consumes the implemented source-update contract in `maintain-patched-omp`; it does not alter updater semantics or the personal plugin contract.

## Impact

Implementation affects `.agents/skills/omp-update/SKILL.md`, `docs/operations/dependency-updates.md`, the README update entry, and Markdown plugin selection in `treefmt.nix`. Verification evidence belongs with this change. No updater code, global skill deployment, plugin input, generated adapter, scheduler, or host configuration change is planned.

The main `personal-omp-workstation` specification still describes the superseded official-installer workflow because `maintain-patched-omp` is not archived. This proposal explicitly references that change's source-update delta and current declarations. It does not close its pending Mac acceptance or launcher-removal tasks, or synchronize its specifications prematurely.
