## Why

The workstation currently installs OMP from Nix but keeps personal behavior, language-server setup, and helper payloads in mutable bootstrap state under `~/.omp/agent`. The bootstrap owns too much state, hides the effective runtime dependency graph, and cannot prove that a new OMP session uses the intended personal policy.

## What Changes

- Consume one immutable personal OMP plugin from the independently pinned `omp-agent-setup` flake.
- Make the default `omp` command launch the pinned OMP package with that plugin and a curated language-server `PATH`.
- Keep OMP authentication, preferences, sessions, history, caches, and Herdr's generated extension mutable under OMP ownership.
- Reconcile the supported Herdr OMP integration without copying its generated source into Nix.
- Replace bootstrap-era LSP installation and synthetic audits with a fixed representative language smoke matrix and a real wrapped-session activation check.
- Remove the global mutable OMP bootstrap, symlink deployment, source patching, executable repointing, and global package installers after cutover passes.

## Capabilities

### New Capabilities

- `personal-omp-workstation`: Reproducible OMP executable, immutable personal plugin, curated language servers, mutable runtime-state boundary, Herdr reconciliation, and activation verification.

### Modified Capabilities

None.

## Impact

- `flake.nix` and `flake.lock`: add and pin the personal plugin repository input.
- Home Manager modules: package the wrapped executable, language servers, plugin wiring, Herdr reconciliation, and verification.
- Runtime command: `omp` resolves to the wrapper; the upstream binary remains available internally as the wrapper target.
- Mutable OMP state: preserved in place; only bootstrap-owned deployment artifacts become obsolete.
- `omp-agent-setup`: remains the independent source and release boundary for personal plugin behavior.
- Architecture documentation: records the final package/runtime split and supersedes bootstrap-era command examples.
