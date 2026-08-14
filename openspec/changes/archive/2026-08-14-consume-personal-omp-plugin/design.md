## Context

The accepted architecture in `docs/architecture/personal-omp-environment.md` splits the system into two repositories. `omp-agent-setup` owns immutable personal behavior. `nix-darwin` owns the pinned executable, plugin revision, language-server packages, wrapper, activation, and cleanup. OMP and Herdr continue to own mutable runtime state.

The existing setup in `omp-agent-setup` deploys mutable files into `~/.omp/agent`, patches an installed OMP source tree, installs global runtimes, and exposes extra workflow commands. Those mechanisms predate OMP's package plugin support and obscure which store artifacts a session uses.

## Goals / Non-Goals

**Goals:**

- One reproducible default `omp` command.
- Independently pinned OMP and personal-plugin revisions.
- Immutable personal extension, skills, policy, and minimal LSP overrides.
- Curated Nix language-server closure without ambient Homebrew, npm, or Bun globals.
- Explicit preservation of mutable OMP state.
- Supported Herdr integration lifecycle.
- Repeatable matrix and real-session cutover evidence.
- Clean removal of superseded deployment paths.

**Non-Goals:**

- Declaratively managing credentials, provider preferences, sessions, history, caches, logs, or Herdr's generated source.
- Moving the personal plugin source into `nix-darwin`.
- Creating one wrapper per operation or preserving `omp-skill` and `omp-plans` aliases.
- Vendoring language ecosystems for ordinary repository development.
- Migrating unrelated repository-specific skills into the personal plugin.

## Decisions

### Two independently locked flake inputs

`nix-darwin` consumes OMP from `llm-agents` and the personal plugin from the `omp-agent-setup` flake. The wrapper receives both resulting store paths. It never reads the plugin's mutable checkout.

Alternative: copy plugin files into `nix-darwin`. Rejected because it creates two personal-policy sources and couples plugin releases to workstation releases.

### One wrapper owns runtime composition

A `writeShellApplication` package becomes the `omp` installed in `home.packages`. Its runtime inputs are the curated language servers. It invokes the upstream OMP binary with `--plugin-dir <store-plugin>`. The upstream package is not separately installed in the user profile, so command precedence is unambiguous.

Alternative: package one app for each OMP verb. Rejected because the OMP CLI already owns operation dispatch and the wrappers would duplicate its contract.

### Preserve the entire mutable state root

The wrapper changes executable inputs, not OMP's state location. `~/.omp/agent` remains a normal writable directory. Home Manager does not symlink the directory or its `config.yml`, databases, blobs, histories, logs, sessions, or caches into the store.

Personal immutable policy loads from the plugin directory. The Herdr extension remains the one deliberate generated file in the mutable extensions directory.

### Herdr reconciles its own generated extension

Activation queries the pinned Herdr CLI. It runs `herdr integration install omp` only when the status reports the integration missing or outdated. Nix does not duplicate the integration payload or infer its version from source text.

### Minimal LSP overlay plus curated executable closure

OMP's built-in server catalog remains the base. The plugin contains only two meaningful overrides:

- select Microsoft Roslyn and disable competing C# servers;
- correct Svelte root markers.

The wrapper PATH provides the selected C#, Python, TypeScript/JavaScript, Svelte, Nix, Markdown, and LaTeX/BibTeX executables from the same `nixpkgs` revision as the workstation.

### Evidence gates cleanup

The cutover order is dependency-driven:

1. package and test the plugin independently;
1. pin it in the workstation flake;
1. build and activate the wrapper and Herdr reconciliation;
1. exercise the fixed LSP matrix;
1. launch a real wrapped OMP smoke session;
1. remove the bootstrap-era deployment graph;
1. run the final build, activation, rollback, and documentation checks.

Cleanup does not begin before the real wrapped session passes.

## Risks / Trade-offs

- A plugin update now requires a plugin repository revision and a workstation lock update. This is intentional release control.
- Language-server packages increase the wrapper closure. The closure is explicit and measurable; unrelated development ecosystems stay outside it.
- Herdr's CLI output is a lifecycle contract. Activation uses its supported status/install interface and fails clearly if that interface changes.
- A real session smoke depends on configured model credentials. It is a cutover check, not a pure flake build.
- Linux CI can validate the plugin package, while activation and rollback remain macOS workstation checks.

## Migration Plan

1. Deliver and validate the immutable plugin package in `omp-agent-setup`.
1. Publish a plugin revision and lock it in `nix-darwin`.
1. Add the wrapper, curated language-server inputs, Herdr activation entry, and deterministic checks.
1. Activate Home Manager without deleting mutable OMP state.
1. Run the matrix and real-session smoke.
1. Remove the old global bootstrap and generated deployment paths from `omp-agent-setup` and the workstation.
1. Rebuild and reactivate. Verify the wrapper, state preservation, Herdr status, and rollback.

Rollback is a `nix-darwin` generation rollback. Because mutable OMP state is never migrated or replaced, rollback changes executable and plugin store paths without restoring databases or configuration.

## Open Questions

- The official ASD-STE100 Issue 9 PDF requires the owner's external request and human audit. Until supplied, the packaged skill must retain its explicit unverified status and non-compliance disclaimer.
