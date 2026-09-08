---
name: omp-update
description: Update or upgrade the personal patched OMP runtime from this nix-config repository. Use for OMP update requests, omp-dev-update failures, patch conflicts, stale updater pins, and source-version recovery. Continue through authorized repair, runtime selection, and verification.
---

# Update personal OMP

Produce a selected, verified OMP runtime on the requested host. A repaired branch, pin commit, or version string alone is not completion.

## Load the procedure

Resolve the checkout root containing this skill. All repository paths below are relative to that root, not this skill directory. Do not use `skill://` parent traversal.

1. Read `README.md` sections **Develop**, **Activate**, **Update**, and **Recover** for current commands and gates.
1. Read `docs/operations/dependency-updates.md` sections **Agent-led OMP updates**, **Release smoke**, and **OMP version recovery**.
1. Read **Refresh the maintained patches** in that document only when a patch repair is needed.

Read current declarations and installed inputs as directed by the procedure. Do not substitute remembered releases, hashes, checkout paths, or past host verification.

## Complete the update

1. Identify the host, command ownership, selected and previous generations, installed versus repository pins, and granted scope. Default to the current supported host, not the fleet.
1. Follow the procedure's preflight. A request to update OMP covers the normal updater's current-host runtime selection unless the user restricts it. It does not grant publication or unrelated host changes.
1. Run `omp-dev-update` when inputs and scope permit. If the user already reported a failure, inspect that failure first rather than rerunning it for confirmation.
1. Branch on the observed result:
   - **Selected or unchanged:** continue to verification. Do not refresh patches or activate Nix without a reason.
   - **Stale installed pins:** reuse an existing reviewed pin commit; verify the configuration and obtain missing activation authorization before retrying. Do not require a nix-config push for local activation.
   - **Patch conflict:** refresh and verify the maintained range in a separate worktree. Obtain explicit publication permission, publish the reviewed range, integrate its exact pins, complete applicable activation, and resume the update.
   - **Other preparation failure:** diagnose the reported phase and repair its cause. Never suppress checks or switch to an official executable fallback.
   - **Rejected after selection:** follow authorized source recovery and verify the recovered runtime. Recovery is not a successful upgrade.
1. Run `verify-personal-omp` and complete the documented release smoke in a fresh wrapped session through Herdr. Include the applicable WSL browser check. An existing session can still run the old generation.
1. Continue through all authorized steps. If an approval, credential interaction, or real prerequisite is unavailable, finish reachable safe work and state the exact blocker and next action.

## Preserve boundaries

- Keep active generations, failed-candidate evidence, previous generations, developer work, and mutable OMP state intact. Never repair an active or failed updater worktree in place.
- Request missing publication permission for the concrete repository and branch. Fork publication does not authorize a nix-config push, force-push, or fleet activation.
- Review and commit only task-owned changes. Follow the personal commit policy and applicable OpenSpec workflow for permanent behavior changes.
- Use the existing updater, supported Herdr integration, and host commands. Do not add an updater, global installation, scheduler, configuration rewrite, or fallback.
- Do not request secret contents. An unavailable administrator interaction is a blocker, not permission to bypass authentication.

## Report the result

State **updated**, **already current**, **recovered**, or **blocked**. Include:

- Host, selected release, upstream commit, patch base and tip, and resulting runtime commit.
- Observed verifier and fresh-session smoke results, including immutable plugin and current Herdr integration.
- Previous-generation availability and any sessions still using an older generation.
- Commits, publications, and activations actually performed; any remaining blocker and exact operator action.

Keep evidence in the relevant change or session. Do not put release-specific facts into this skill or current-state manuals.
