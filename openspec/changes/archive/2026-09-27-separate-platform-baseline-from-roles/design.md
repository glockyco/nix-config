## Context

Change 1 provides standalone typed declarations in `hosts/<name>/host.nix`, a read-only `fleet.hosts` registry, typed `config.fleet.hosts`, `packages/<name>/`, `checks/`, and separate flake modules. Change 2 records its own Windows byte baseline and may intentionally change two rendered files. At this change's start, record the completed change 2 output as this change's Windows byte baseline. Record pinned-revision system derivations separately.

At HEAD, the platform imports contain machine functions (`modules/darwin/default.nix:2-15`, `modules/nixos/default.nix:5-13`). Both host files provide inline `host` values and Home Manager overrides (`hosts/macbook-pro/default.nix:25-45`, `hosts/korolev/default.nix:25-63`). The current screenshot directory appears in two modules (`modules/darwin/defaults.nix:121-126`, `modules/home/darwin/screenshots.nix:8-17`). Git identity, Dock entries, Colima capacity, and platform-specific shell initialization have similar split ownership (`hosts/korolev/default.nix:41-60`, `modules/darwin/defaults.nix:89-104`, `modules/home/darwin/container-runtime.nix:10-24`, `modules/home/shell.nix:10-15`).

The Air currently uses literal SSH aliases, a checked batch command, Finder's numbered mount path, and a link (`modules/home/darwin/ssh.nix:12-16,38-39,76-92`, `packages/air-batch-check.nix:20-26`, `modules/home/darwin/network-shares.nix:9-45`). The current SOPS rule encrypts only three value names (`.sops.yaml:7-17`), while the tracked YAML has readable SOPS metadata (`secrets/fastmail.yaml:1-16`).

## Goals / Non-Goals

**Goals:**

- Keep platform baselines reusable and select optional roles at each host.
- Keep each durable machine fact in a typed standalone host declaration; derive consumers and checks from that fact.
- Preserve existing Air and PostgreSQL behavior while making Air removal bounded.
- Preserve Windows output bytes and behavior-preserving system derivations.
- Reject plaintext YAML secret data in repository checks. Keep the Mac SOPS recipient and current `encrypted_regex`.

**Non-Goals:**

- Add the Air or Windows desktop to the managed-host registry. They are tailnet peers, not host configurations (`modules/shared/tailnet-peers.nix:1-13`).
- Move the PostgreSQL data directory or alter database ownership. The cluster remains at `/var/lib/postgresql/17`; its existing directory-creation activation remains in the PostgreSQL module (`modules/darwin/postgresql.nix:35-40`).
- Change Air SSH, SMB, Docker-path, or credential behavior. Issue #17 removes this temporary integration after result preservation.
- Change Windows renderer semantics or output bytes from the completed change 2 output. Change 2 owns the renderer.
- Change activation program behavior. `package-user-programs` owns those changes at position 4.

## Decisions

### 1. Platform directories contain baselines; roles own optional machine functions

`modules/darwin/default.nix` and `modules/nixos/default.nix` retain integration needed by every host of their platform. The current lists import machine functions directly (`modules/darwin/default.nix:6-13`, `modules/nixos/default.nix:6-12`). Move optional functions to:

```text
modules/roles/darwin/desktop/default.nix
modules/roles/darwin/postgresql/default.nix
modules/roles/darwin/container-client/default.nix
modules/roles/darwin/air-client/default.nix
modules/roles/nixos/wsl-workstation/default.nix
```

Each host's `default.nix` imports its own `host.nix`, platform baseline, and selected roles. The Mac selects all four Darwin roles; Korolev selects `wsl-workstation`. A role imports its system and Home Manager modules together. The desktop role owns Homebrew, Dock, macOS defaults and GUI apps; PostgreSQL owns its service and `install -d`; container-client owns Colima; Air-client owns only Air-specific integration. The WSL role owns WSL integration and rootless containers. A baseline does not import a role.

Alternative rejected: a shared role tree with platform branches. It would repeat the platform leakage removed by role selection. Alternative rejected: computed `imports` from `host.roles`. Imports resolve before configuration options, and this approach makes module selection recursive.

### 2. Extend standalone typed host facts, not a second flake table

Change 1 types `host.name`, `host.username`, `host.system`, `host.kind`, builder data, and tailnet data in `modules/fleet/host.nix`; it evaluates only `hosts/<name>/host.nix` to build `fleet.hosts`. Add typed `host.displayName`, `host.timeZone`, locale and format values, `host.paths.configurationCheckout`, `host.paths.screenshots`, `host.git` identity and email policy, `host.darwin.applications`, and positive `host.darwin.containerProfile` capacity and mounts. Put assignments in `hosts/macbook-pro/host.nix` and `hosts/korolev/host.nix`; keep role imports and per-machine Home Manager wiring in their `default.nix` files. A standalone declaration sets only `host.*`, so registry evaluation does not evaluate full configurations.

A module reads its own typed values from `config.host`; cross-host consumers read `config.fleet.hosts`. Neither platform module nor check repeats a host-specific literal. This extends change 1's registry rather than adding independent `fleet.hosts.<name>` facts. Platform-only option values can be nullable; the role that consumes one asserts that it is set. Assertions reject empty required strings and nonpositive Colima capacity.

Alternative rejected: inject role data through extra module arguments. Those arguments bypass the typed declaration. Alternative rejected: put a second inventory in flake modules. It would diverge from standalone host files and create cross-host evaluation.

### 3. Identity, applications, and paths have one durable source

Git identity has one author name, default email, and GitHub no-reply email under `host.git`. The Mac uses no-reply by default; Korolev uses its employer address by default and a personal-repository include (`hosts/macbook-pro/default.nix:32-39`, `hosts/korolev/default.nix:41-60`). Derive the include path from evaluated `programs.git.settings.ghq.root`, currently set by `modules/home/ghq.nix:6`, rather than repeat `~/src`.

A typed `host.darwin.applications` record has an optional cask, app path, optional Dock position, and rationale. The desktop role derives Homebrew casks and ordered Dock application entries from those records. Keep the existing Dock spacer and `persistent-others = [ ]` as policy (`modules/darwin/defaults.nix:89-108`). Assert unique non-null casks, app paths, and Dock positions. Homebrew currently declares its casks independently (`modules/darwin/homebrew.nix:25-37`); Dock currently pins paths independently (`modules/darwin/defaults.nix:89-104`).

The Darwin screenshot default and Home Manager directory use `host.paths.screenshots`; the packaged `darwin-switch` receives `host.paths.configurationCheckout` and a pinned `darwin-rebuild` executable. The nix-homebrew profile fragment moves from portable shell initialization to the Darwin desktop user module. This preserves the Mac output but removes the misplaced Homebrew path adjustment from Korolev's generated zsh configuration.

Alternative rejected: keep separate cask and Dock lists with a consistency assertion. Two inventories still require paired edits. Alternative rejected: leave a Darwin branch in portable shell code. It hides ownership instead of moving it.

### 4. Air is a bounded deletion unit, not a new durable declaration

The `air-client` role imports Air-only SSH aliases from `modules/home/darwin/ssh.nix:76-92`, installs `air-batch-check` from `ssh.nix:12,38-39`, imports the SMB agent and `~/Air` link from `modules/home/darwin/network-shares.nix:9-45`, and owns the Air-specific check selection. Keep the current destination, account, Finder-selected `/Volumes/Macintosh HD-1` path, and `AIR_BATCH_DOCKER` command interface (`modules/home/darwin/ssh.nix:13-16`, `modules/home/darwin/network-shares.nix:9-33`, `packages/air-batch-check.nix:20-25,49-59`). Move these without changing them.

Change 1 moves the combined Air and desktop SSH assertion to `checks/air-batch-config-check.nix`; the current check tests both endpoints (`packages/air-batch-config-check.nix:21-65`). Split out durable desktop assertions into `checks/desktop-batch-config-check.nix`, and leave only Air assertions in `checks/air-batch-config-check.nix`. Keep the desktop check wired after Air removal. Under change 1's layout, Air deletion removes `modules/roles/darwin/air-client/`, `packages/air-batch-check/` including its tests, `checks/air-batch-config-check.nix`, the Air role import in `hosts/macbook-pro/default.nix`, the role-selection export condition in `flake-modules/packages.nix`, the two Air check branches in `flake-modules/checks.nix`, and `macbook-air` in `modules/shared/tailnet-peers.nix`. The flake exports the Air package, and generates its command and configuration checks, only for a system where a host selects the Air role; the evaluated Air SSH alias identifies that selection. Air-only Home Manager modules move into the role directory; no baseline or durable role references them. Air check selection follows the role, and a temporary removal probe proves durable host outputs and desktop release gates remain. Keep the peer entry until issue #17 offboards the machine.

Alternative rejected: typed `host.remote.air`, an explicit stable mount, and a derived Docker executable. All three polish integration that issue #17 removes. Alternative rejected: let the flake publish Air checks unconditionally. That would leave the Air in release gates after role removal.

### 5. PostgreSQL moves as a module without storage migration

Move the existing module into the Darwin PostgreSQL role without changing its service, package version, initialization, authentication, or `install -d` activation (`modules/darwin/postgresql.nix:4-40`). Preserve the existing `/var/lib/postgresql/17` data directory and its live data. Its idempotent directory preparation stays with the service. A role move must not initialize a new cluster or add a migration task.

Alternative rejected: relocate the data directory as part of a module move. The owner's existing research data makes that an unnecessary and risky behavior change.

### 6. Shared Nix policy has native platform adapters

Declare the pinned nixpkgs registry, disabled legacy channels, and maintenance intent once. Darwin maps the registry and an empty `nix-path` through Determinate Nix, which disables nix-darwin's `nix.settings`, `nix.registry`, `nix.gc`, and `nix.optimise`. The pinned Determinate module supports automatic garbage collection through `determinateNixd.garbageCollector.strategy`, but exposes no weekly schedule or scheduled store optimiser. Do not set `auto-optimise-store` on Darwin: pinned nix-darwin warns that it can corrupt the store. NixOS maps the shared intent to a pinned registry, disabled channels, and native weekly garbage-collection and optimisation timers. Check evaluated values and preserve Darwin `trusted-users`: Korolev sends unsigned store paths to the remote builder.

Remove NixOS `programs.nano.enable` and the normal-user home assignment only after evaluating pinned module defaults and confirming unchanged `programs.nano` and `/home/<user>` (`modules/nixos/programs.nix:72-76`, `modules/nixos/system.nix:38-46`). The new NixOS Nix policy changes Korolev's generated services; compare the derivations with `nix-diff` and build the CI Linux check.

Alternative rejected: copy Darwin option syntax directly to NixOS or add a custom Darwin launchd maintenance job. Determinate Nix owns Darwin store maintenance and does not expose the same timer interfaces.

### 7. Zen's macOS enablement belongs to Darwin, with no Windows byte change

Move `EnterprisePoliciesEnabled` from shared Zen policy data to the Darwin Zen module (`modules/shared/zen-policies.nix:11-14`, `modules/darwin/zen.nix:8-13`). Remove the renderer's `removeAttrs` compensation after change 2 has moved that renderer to `packages/windows-configuration/` (`modules/windows/files.nix:234-236` is the current source). Compare every rendered file with this change's section 1 baseline, recorded from the completed change 2 output. Require byte and hash identity, not equivalent parsed JSON.

Alternative rejected: keep a shared macOS-only key and make Windows delete it. That retains a consumer-side exception to a misplaced declaration.

### 8. Colima capacity comes from the host; architecture comes from the package platform

Render CPU, memory, disk, and mounts from `host.darwin.containerProfile`. Render `arch` from `pkgs.stdenv.hostPlatform.qemuArch`. Keep runtime, VM type, Rosetta, mount type, isolation, and lifecycle under the container-client role. These values currently coexist as literals in `modules/home/darwin/container-runtime.nix:10-33`; the config check repeats CPU, disk, memory, and architecture literals in `packages/container-runtime-config-check.nix:43-52`. Update that check to read evaluated host facts while retaining its policy assertions.

Alternative rejected: put architecture in host data. The supplied package set already defines it. Alternative rejected: put all Colima policy in host data. Runtime and isolation choices belong to the role.

### 9. One secrets helper renders opt-in XDG functions

Use one Nix function to render both Cloudflare direnv functions through `xdg.configFile`. Keep the exact shell behavior and secret paths from `config.sops.secrets`. The current functions duplicate control flow and use `home.file` for paths under `.config/direnv` (`modules/home/darwin/secrets.nix:43-73`). A byte comparison of generated functions proves preservation.

Alternative rejected: a new executable for token exports. A sourced function must mutate the current shell's environment.

### 10. SOPS plaintext check; offline recovery is follow-up work

The Mac remains the only SOPS recipient. `.sops.yaml` retains `encrypted_regex`, and the repository check rejects plaintext data scalars outside SOPS metadata. The README states that offline recovery is not configured. Adding an offline recipient, re-encrypting every secret for both recipients, removing `encrypted_regex`, and proving offline-key decryption belong to a later change.

The repository check lives in `checks/secret-encryption-check.nix` with adjacent fixtures. `flake-modules/checks.nix` wires it on every supported system. It visits YAML data outside the top-level `sops` metadata mapping and reports the file and YAML path for each plaintext scalar. Fixture tests cover nested mappings, sequence entries, and encrypted data. The check does not decrypt; CI has no private keys. An in-memory Mac-key round trip confirms the existing files decrypt without changing their ciphertext.

Alternative rejected: another name allowlist. Future YAML keys would bypass encryption. Alternative rejected: a Korolev recovery recipient. That online host has no workstation secrets (`flake.nix:727-734`) and is not offline recovery.

## Risks / Trade-offs

- Role moves change import boundaries. Compare pinned-revision system derivations after each behavior-preserving cutover. Use `nvd diff` for built Mac closures and `nix-diff` for changed Korolev derivations.
- Windows renderer input changes. Require byte identity against the completed change 2 output recorded before this change's edits.
- The Air remains order-dependent while borrowed. This is an accepted temporary risk; the role-removal probe and issue #17 bound its lifetime.
- The current SOPS setup has no offline recovery recipient. The README identifies this limit; adding recovery is separate work.
- NixOS maintenance introduces timers. Evaluated units, a `nix-diff` comparison, and the Linux CI build verify the repository change, not activation on Korolev.

## Migration Plan

1. Record the parent commit, lock checksum, completed change 2 Windows output bytes, evaluated Air/Colima/Nix/SOPS facts, and both pinned-revision system derivation paths.
1. Extend standalone typed host declarations. Add assertions and cut existing consumers over to `config.host`.
1. Create selected role directories. Move one optional function at a time and compare both system derivations after each behavior-preserving move.
1. Isolate Air without changing its commands, mount path, or credentials. Prove role deletion leaves durable outputs valid.
1. Move Zen enablement and remove Windows compensation. Prove byte identity to this change's section 1 Windows baseline.
1. Apply Nix policy, Colima derivation, and direnv helper changes; verify intentional differences separately.
1. Keep the existing SOPS recipient and ciphertext. Add the parsed-data repository check and verify Mac-key decryption in memory.
1. Update affected README, operations pages, and adjacent code comments. Run Mac gates and review CI results on both platforms.

Rollback uses a reviewed Git revert plus activation of the prior host generation. The encrypted files and Mac key remain unchanged. Air offboarding removes the listed integration units; it does not migrate a mount or remote Docker path.
