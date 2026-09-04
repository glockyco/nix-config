## Context

This change starts after `declare-typed-host-options`, `connect-fleet-over-tailnet`, and `key-fleet-by-host` are archived. The flake then has a host-keyed table, typed `host` options, generated host outputs, one package set per system, and `flake-modules/` ownership.

The current platform lists import machine roles directly. `modules/darwin/default.nix` imports the desktop, Homebrew, Rosetta, power, and PostgreSQL modules. `modules/nixos/default.nix` imports WSL and container modules. Host identity and user values are split between those modules and both host files.

Several declarations already disagree. `modules/home/darwin/network-shares.nix` expects an order-dependent `/Volumes/Macintosh HD-1` path. `packages/air-batch-check.nix` requires `AIR_BATCH_DOCKER`, but its module does not set it. `.sops.yaml` encrypts only values whose keys match three names, although SOPS already leaves YAML keys readable.

## Goals / Non-Goals

**Goals:**

- Platform baselines that are safe for every host of that platform.
- One explicit import per selected machine role.
- One typed declaration for every identity, path, endpoint, and resource value.
- Checks that derive expectations from evaluated declarations.
- Full SOPS encryption with host and offline recovery recipients.
- A pinned-revision proof for every behavior-preserving move.

**Non-Goals:**

- Adding `air` or the Windows desktop as Nix-managed hosts. `connect-fleet-over-tailnet` declares them as tailnet nodes only.
- Changing activation program behavior. `package-user-programs` owns that work.
- Changing Windows artifact rendering. `derive-windows-check-from-declaration` owns that work.
- Replacing the temporary Air's Apple SSH service or SMB service before the machine is returned.
- Keeping any Air integration after its research results are preserved and the borrowed machine is returned.

## Decisions

### 1. Platform directories contain baselines; platform role directories contain machine functions

`modules/darwin/default.nix` keeps system integration, Nix, shared Home Manager wiring, and the options needed by every Darwin host. `modules/nixos/default.nix` keeps the equivalent NixOS baseline.

Optional functions move under these directories:

```text
modules/roles/darwin/desktop/
modules/roles/darwin/postgresql/
modules/roles/darwin/container-client/
modules/roles/darwin/air-client/
modules/roles/nixos/wsl-workstation/
```

Each role has one `default.nix`. A role may import system modules and add user modules through `home-manager.users.${config.host.username}.imports`. The host imports the role once. `hosts/macbook-pro/default.nix` selects the four Darwin roles. `hosts/korolev/default.nix` selects `wsl-workstation`.

A role directory stays under one platform. Shared modules contain no `stdenv.isDarwin`, `mkIf isDarwin`, or equivalent branch.

Alternative rejected: one shared role tree with platform conditions. It would recreate the platform leakage that `split-home-modules-by-platform` removed.

Alternative rejected: encode role names as `host.roles` and compute `imports` from the option. Module imports resolve before option values, so that shape creates recursion and weakens errors.

### 2. Extend `options.host` with typed machine data

`modules/fleet/host.nix` gains submodules for:

- `displayName`, `timeZone`, and `locale`;
- `paths.configurationCheckout` and `paths.screenshots`;
- `git.authorName`, `git.defaultEmail`, and `git.githubNoreplyEmail`;
- `darwin.applications`, where each item has `cask`, `appPath`, optional `dockPosition`, and `rationale`;
- `darwin.containerProfile`, with positive CPU, memory, and disk values plus mounts;
- nullable `remote.air`, with MagicDNS host, user, batch alias, remote Docker path, SMB share, explicit mount point, and the temporary peer purpose inherited from the tailnet declaration.

Platform-only fields use nullable submodules whose assertions require them only when the selected role reads them. The host file assigns the values beside its role imports.

Alternative rejected: add more arguments to role modules. `declare-typed-host-options` removed that transport because an argument has no central type or ownership.

Alternative rejected: put the data in the flake host table. The table needs only `system` and `kind` to construct a configuration. Machine configuration belongs in the host module and must be visible as `config.host`.

### 3. Git identity has one author declaration and explicit email policy

Both hosts read `host.git.authorName`. `macbook-pro` uses `host.git.githubNoreplyEmail` as its default. `korolev` uses `host.git.defaultEmail` and uses the no-reply address for personal repositories.

The personal include derives its root from the evaluated ghq setting. It renders `gitdir:${config.programs.ghq.root}/github.com/glockyco/` instead of repeating `~/src`.

Alternative rejected: infer the author from an email address. An email is an account policy, not a stable display name.

### 4. One application record generates Homebrew and Dock declarations

`host.darwin.applications` is the inventory. The desktop role derives `homebrew.casks` from `cask` and derives persistent Dock entries from items with `dockPosition`. Evaluation sorts Dock items by that position. Assertions reject duplicate casks, application paths, and Dock positions.

An application not shown in the Dock has no `dockPosition`. A Dock-only item has no cask only when macOS supplies it. The rationale remains data because it explains why activation installs or pins an application.

Alternative rejected: keep a cask list and assert that every Dock path has a matching cask. Two lists still require two edits and cannot express macOS-supplied applications cleanly.

### 5. Screenshot and checkout paths come from evaluated configuration

The Darwin defaults module writes the screenshot location from `host.paths.screenshots`. The user module creates that same path. The `darwin-switch` package receives `host.paths.configurationCheckout` and includes the pinned `darwin-rebuild` executable in `runtimeInputs`. Its script calls `lib.getExe` rather than resolving `darwin-rebuild` from the caller's `PATH`.

The nix-homebrew profile fragment moves from portable `modules/home/shell.nix` into the Darwin desktop user module. It derives the profile path from `config.home.profileDirectory`.

Alternative rejected: guard the portable fragment with `osConfig ? homebrew`. A platform probe in portable code hides ownership and keeps Darwin behavior in the shared module.

### 6. The temporary Air declaration owns one removable integration

The `air-client` role is the only consumer of `host.remote.air`. It owns the SSH aliases, batch program, batch configuration check, SMB mount agent, `~/Air` link, and their mutable credential references. No baseline, durable role, release gate, builder, storage declaration, or authentication path depends on them.

The Air client role renders both SSH aliases from `host.remote.air`. It passes `remoteDockerExecutable` directly to `pkgs.air-batch-check`. The package has a required `remoteDockerExecutable` argument and no `AIR_BATCH_DOCKER` fallback. Its fixture test overrides the argument.

`packages/air-batch-config-check.nix` receives the evaluated SSH settings and derives the destination host and user from the interactive alias. It asserts that the batch alias has the same destination and the declared non-interactive settings.

The SMB mount uses the declared MagicDNS name and an explicit directory such as `~/Library/Mounts/air`. The mount program creates that directory and calls `/sbin/mount_smbfs -N` with the declared share. The operator keeps the credential in the macOS SMB credential store. `~/Air` points to the explicit mount point. No code discovers or predicts a numbered `/Volumes` path.

Alternative rejected: find the first `/Volumes/Macintosh HD*` directory. That turns mount order into an implicit selector and can bind the wrong server.

A temporary evaluation removes the `air-client` import and sets `remote.air = null`. The Mac must still evaluate, and no generated package, check, launchd agent, SSH alias, Home Manager file, or policy consumer may reference the Air. This is the implementation proof for the offboarding issue created by `connect-fleet-over-tailnet`.

Alternative rejected: keep `osascript mount volume` and inspect Finder's selected path. Finder still owns the unstable suffix, so consumers cannot have a declared target.

### 7. Shared Nix policy has platform adapters

`modules/shared/nix-policy.nix` owns the pinned registry entry, disabled legacy channels, garbage-collection cadence, and store optimisation policy as data. Thin Darwin and NixOS modules map that policy to their native option shapes.

Both hosts set `nix.registry.nixpkgs.flake = inputs.nixpkgs` and disable channels. Both run weekly garbage collection and weekly optimisation. Their exact scheduler syntax may differ, but the cadence and retention policy are one declaration.

The Darwin `trusted-users` entry stays. `connect-fleet-over-tailnet` needs it because `korolev` sends unsigned input paths to the remote builder. The old substituter rationale leaves.

The explicit `programs.nano.enable = true` leaves because the pinned NixOS module already defaults to true. The explicit normal-user home leaves because the pinned users module derives `/home/<name>` for `isNormalUser`.

Alternative rejected: copy the Darwin option block into NixOS. The two module systems expose different scheduler options, and copied syntax would not be shared policy.

### 8. Zen's macOS policy belongs to the Darwin desktop role

`EnterprisePoliciesEnabled` moves from `modules/shared/zen-policies.nix` to the Darwin Zen module. The Windows renderer stops deleting it with `removeAttrs`. Shared Zen policy data then means the same thing on both consumers.

Alternative rejected: leave the key shared and keep the Windows compensation. A producer should not publish data that one consumer must repair.

### 9. Colima resource values belong to the host; architecture belongs to the platform

The container-client role reads CPU, memory, disk, and mounts from `host.darwin.containerProfile`. It renders `arch = pkgs.stdenv.hostPlatform.qemuArch`. Runtime, VM type, Rosetta, mount type, and isolation values remain role policy.

Alternative rejected: declare `arch = "aarch64"` in the host. Architecture already has an authoritative source in the supplied package set.

Alternative rejected: move all Colima fields into the host declaration. Runtime and isolation are role policy, not machine capacity.

### 10. One secrets helper renders XDG direnv functions

The secrets module defines one Nix helper that takes the function name, secret option, and failure label. It renders both direnv functions through `xdg.configFile`. The token paths still come from `config.sops.secrets`.

Alternative rejected: install a general token-export executable. The functions must mutate the caller's shell environment, so they must remain sourced shell functions.

### 11. SOPS encrypts every scalar and includes an offline recovery recipient

The `encrypted_regex` and its incorrect comment leave. The creation rule has two age recipients: the existing Mac recipient and a new public recipient whose private key is generated on offline encrypted media. Only the public recipient enters the repository. The implementation re-encrypts every secret file before it removes the regex.

`packages/secret-encryption-check.nix` parses each YAML file and walks mappings and sequences recursively. Every scalar leaf must be a string that starts with `ENC[`. The check prints the file and a dot-separated scalar path. Fixture tests cover a nested plaintext value, a plaintext list item, and a fully encrypted shape.

The check does not decrypt. CI has no private key, and the encrypted prefix is the committed-state contract it can prove. The live gate decrypts one file with the Mac key and one with the offline key before the old files are replaced.

Alternative rejected: encrypt only a wider list of key names. Any allowlist can miss the next name, and SOPS does not encrypt YAML keys.

Alternative rejected: add `korolev` as recovery recipient. The tailnet design intentionally gives `korolev` no workstation secret, and an online work machine is not offline recovery.

## Risks / Trade-offs

- The role move touches many import paths. The pinned-revision derivation gate runs after each role cutover, not only at the end.
- `mount_smbfs -N` depends on a credential outside Nix. The current Finder mount already depends on mutable credentials. The live gate proves the non-interactive mount before the old path leaves.
- Full-file SOPS encryption creates a one-time diff in every secret file. The parsed-scalar check and two-recipient decrypt proof distinguish intended ciphertext churn from missing data.
- Weekly Nix maintenance changes the NixOS service surface. Its timers and the retained generations are verified on `korolev`; it is not included in the closure-identity claim.
- Moving `EnterprisePoliciesEnabled` changes the Windows renderer input. The rendered Windows policy must remain equal because the Windows path already removed that key.

## Migration Plan

1. Record the parent commit, `flake.lock` checksum, and both pinned-revision system derivation paths in `baseline.md`.
1. Add the host option types and move identity, Git, path, application, container, and Air values into both host declarations.
1. Create the platform role directories. Move one role at a time and confirm both derivation paths after each move.
1. Cut consumers over to the typed values. Remove every old literal and compatibility path in the same step.
1. Add the shared Nix policy and intentional NixOS maintenance behavior. Verify its evaluated options and live timers separately.
1. Generate and store the offline recovery key. Add its public recipient, re-encrypt every secret, remove `encrypted_regex`, and run both decrypt proofs.
1. Add the secret fixture check and all declaration-driven checks.
1. Run the static gates, activate each affected host, and run the Air mount and batch checks.

Rollback is a Git revert plus activation of the previous generation. Keep the prior encrypted files and both private age keys until each decrypt proof passes. Keep the old Air mount available until the explicit mount completes once. The future Air offboarding removes the role and declaration instead of preserving either mount path.
