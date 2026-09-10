## Context

See `proposal.md` for motivation. `packages/personal-omp.nix` wraps the host-declared executable and injects the locked plugin and language tools. It routes `omp update` to Homebrew on Darwin or the standalone updater on WSL. `modules/home/omp.nix` already supplies the shared package and verifier.

The current Korolev launcher runs a source checkout through its pinned Nix development environment. Upstream supplies a portable development shell and `packages/coding-agent/scripts/omp`, including working-directory preservation and Darwin/Herdr handling. Upstream `bun run setup` also creates global links, so the updater must not invoke that aggregate command.

The personal GitHub fork exists, but its remote lacks `fix/wsl-terminal-hyperlinks`. The reviewed patch series currently exists only in Korolev's checkout. No host may depend on that checkout or on access to Korolev.

## Goals / Non-Goals

**Goals:** one explicit updater, independent host-local generations, portable shell dependencies, and unchanged plugin and application-state ownership.

**Non-Goals:** custom releases, unattended scheduling, automatic conflict resolution, patch publication during updates, upstream updater compatibility, or a general package manager.

## Decisions

### Use a shared Git patch source

Declare the fork URL, upstream base commit, and patch-tip commit as one reviewed input to the updater package. Fetch the exact commits and verify their ancestry. Keep the five fixes as Git commits, not copied `.patch` files or duplicated source in nix-config.

Publish the existing branch to `glockyco/oh-my-pi` only after explicit permission. No new fork or release infrastructure is required. Patch changes require an explicit pin update; a moving remote branch cannot silently change the code installed on another host.

### Prepare each generation at its final path

Use the same home-relative state root on both hosts: `~/.local/share/omp-dev`. It contains a Git repository, generation directories, and `current` and `previous` links. Each generation records its upstream release, patch input, resulting commit, host system, and development-environment profile.

Create a detached candidate worktree directly in its generation directory. Rebase the pinned patch range onto the latest non-draft, non-prerelease upstream release. Do not mutate the developer checkout or the active generation. Do not rename a prepared worktree: dependencies can contain absolute paths.

A Python command packaged by Nix can use standard-library filesystem locking and atomic link replacement on both platforms. Declare its Git, GitHub CLI, and Nix dependencies; do not rely on macOS's system Python or GNU-only shell behavior.

### Prepare the real runtime, not only TypeScript

Use the candidate's locked upstream Nix development shell, with a retained per-generation profile. Run dependency installation with the frozen Bun lockfile, then prepare the host native addon. Do not run setup's global linking steps. Use the upstream development launcher instead of introducing another Bun preload workaround.

Run the relevant package checks and patch regressions. Also start the candidate through the workstation plugin configuration and verify that the host native addon loads. Every failed command prevents promotion. Each host prepares its own runtime. Neither host reads the other host's checkout or build output.

### Install the published addon instead of a local compile

The addon is the only compiled component of a generation. The maintained series patches TypeScript only, so the addon that upstream built for the candidate release matches the candidate sources. Install that published platform package with the upstream artifact install mode, which the upstream native command already supports. Only the addon binary is a build output; upstream tracks the remaining binding files in Git.

Verify the published integrity digest and the published provenance attestation before installation. A failed verification fails the native phase and leaves the selection unchanged. Do not install an unverified file, and do not use a release executable instead.

Compile the addon in the candidate development shell when the maintained range changes Rust crates, the native package, or the workspace build files. Compile it also when no published addon matches the candidate release and platform. The updater derives this condition from the pinned patch range, so a future native patch cannot silently receive a foreign binary.

### Share downloaded packages between generations

Keep one persistent package cache for the updater under the state root. Dependency installation and any addon compile read and write that cache. A cache holds verified downloads, not agent state, so sharing it preserves the isolation goal.

Candidate verification keeps its own home, configuration, agent, and session directories. The cache is disposable: its removal changes no selected generation and no recorded metadata.

### Promote once, after verification

Serialize updates and rollback with a process-held file lock. Replace `current` atomically only after all candidate preparation succeeds. Retain the old target as `previous`; a first installation has no previous target. Existing sessions continue using their original generation, which is not automatically deleted.

A repeated update with unchanged release and patch inputs is a no-op. Conflicts, network errors, dependency failures, interrupted preparation, and verification failures leave `current` unchanged. Report the failed phase and candidate location for diagnosis. Do not use conflict-resolution strategies that discard changes.

Provide `omp-dev-update --rollback` to select the previous verified generation without network access. Reject rollback when no previous generation exists. Nix garbage collection must not invalidate the retained generations' development profiles.

### Keep one launch path

The Nix-managed `omp` wrapper resolves the selected generation once, then launches it with the existing immutable plugin and curated tools. Missing initialization reports `omp-dev-update`; it does not fall back to Homebrew or an official binary.

Reject a leading `omp update` with a clear instruction to use `omp-dev-update`. Preserve other arguments, including `omp acp` and non-leading text named `update`. Keep plugin update operations available through their documented plugin commands; do not reinterpret executable-update flags.

Activation installs the wrapper and updater, but performs no downloads, source preparation, native builds, or OMP launches. Herdr reconciliation remains unchanged. Remove obsolete host-specific executable/update routing from declarations and checks.

## Risks / Trade-offs

- Upstream changes can break a patch or build command. Fail without promotion; adjust the maintained series explicitly.
- Source preparation is slower and uses more disk than an official binary. Retain working generations rather than trading recoverability for automatic cleanup.
- A published addon is an additional supply-chain input. Accept it only for the exact candidate release, with a verified digest and provenance. Its publisher already owns the release sources that the generation runs.
- A native patch would invalidate a published addon. Derive the compile condition from the pinned range, not from an operator decision.
- New release code executes during installation and any native build. Use only the declared upstream and pinned patch source; never fetch patches from arbitrary model output.
- Portable evaluation alone does not prove Darwin execution. Require actual macbook-pro and Korolev preparation, launch, update, and rollback evidence before acceptance.
- This reverses existing no-source-update policy. Update its accepted requirements and guidance together, without relaxing unrelated activation or credential boundaries.

## Migration Plan

1. Obtain permission and publish the clean patch branch to the existing fork; verify both hosts can fetch its pinned commits.
1. Build the new updater on both hosts and prepare the first generations explicitly before switching the default wrapper.
1. Activate the reviewed host configuration, run `verify-personal-omp`, and perform the real wrapped-session smoke on each host.
1. Exercise failed-update preservation, successful promotion, and offline rollback. Retain evidence with this change.
1. Remove the obsolete Korolev `omp-dev` launcher and old default routing after acceptance. Leave the developer Git checkout and existing application state intact. Do not delete installer-owned files implicitly.

Nix rollback restores wrapper/plugin generations, not the selected source generation. The documented OMP rollback command owns source-version recovery. Previous host generations remain available during migration.
