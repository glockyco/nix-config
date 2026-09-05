## Scheduling — 2026-09-05

This change is deferred, not canceled or complete. It is not a prerequisite for wrapped OMP usability or the WSL restart, DNS, MagicDNS, and SSH checks. The scheduling notice below remains authoritative.

The technical proposal, design, specifications, and unchecked tasks remain requirements for future implementation. CLI artifact and task counts describe artifact and task state, not authorization to start work. Work resumes only when a concrete maintenance or use requirement warrants it and the owner schedules the change after another plan review.

## Why

The platform module lists mix operating-system baseline with one machine's roles and identity. That structure makes a second Darwin or NixOS host inherit services, applications, paths, and names that belong only to `macbook-pro` or `korolev`.

The same facts also have several declarations. Examples include the screenshot directory, Git identity, Air endpoint, Dock applications, container sizing, and Nix settings. Several copies have already drifted or become ineffective. The Air is a borrowed research machine that will be returned after the PhD thesis and TOSEM results are retrieved, so its integration must also be removable as one unit.

## What Changes

- Keep `modules/darwin/` and `modules/nixos/` as platform baselines only. Move optional machine functions to `modules/roles/<platform>/<role>/` and let each host select its roles.
- Extend the typed host declaration with machine identity, locale, time zone, repository checkout, screenshot, container-profile, and remote-endpoint data. Consumers read those values instead of literals.
- Declare the Git author once. Let each host select the applicable email policy without repeating the author name or GitHub no-reply address.
- Declare each Homebrew application once with its cask, application path, Dock position, and rationale. Generate the cask set and Dock entries from that list.
- Give the Air share an explicit mount point. Derive every use from the mount declaration instead of relying on the order-dependent `/Volumes/...-1` name.
- Make the Air batch checker receive the declared remote Docker path as a package argument. Derive the checker expectations from the evaluated SSH configuration.
- Isolate every Air endpoint, mount, package, check, and credential reference behind one temporary `air-client` role. Prove that removing the role and declaration leaves the durable workstation configuration valid.
- Pin the Nix registry on both platforms, disable legacy channels, and apply the same garbage-collection and store-optimisation policy where each platform supports it.
- Remove the redundant NixOS `nano` and normal-user home declarations after proving the pinned module defaults.
- Move the macOS-only Zen policy and nix-homebrew path adjustment out of shared modules.
- Derive the Colima architecture from the host platform and read its reviewed resource sizes from the host declaration.
- Replace duplicated secrets helpers with one helper and use the XDG file option for XDG configuration.
- Remove `.sops.yaml`'s value-name allowlist. Add an offline recovery recipient and a behavior check that rejects every unencrypted scalar under `secrets/`.
- Preserve the remote-builder trust added by `connect-fleet-over-tailnet`, but replace the obsolete substituter comment with its actual unsigned-import rationale.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `repository-quality-gates`: separates platform baselines from host roles, requires one declaration per host fact, and rejects plaintext secret scalars.
- `personal-omp-workstation`: expands declared host defaults so identity, locale, paths, and selected roles belong to the host.
- `container-runtime`: derives the declared Apple Silicon profile from reviewed host data and the host platform.
- `batch-ssh`: makes the declared remote Docker path the one value used by automation and its checks.

## Impact

The change affects `modules/darwin/`, `modules/nixos/`, `modules/roles/`, `modules/home/`, `modules/shared/`, `hosts/`, `.sops.yaml`, the Air and secret checks under `packages/`, and the host/check generators under `flake-modules/`.

Most moves preserve behavior. The pinned-revision system derivation gate proves each structural step. The intentional behavior changes are separate: NixOS gains the shared registry, channel, garbage-collection, and optimisation policy; the Air mount gets a stable path; the batch checker receives the actual Docker path; and SOPS encrypts every scalar for both the host and an offline recovery key. Each change has a direct evaluation, fixture, or live-host proof.

This change assumes that `declare-typed-host-options`, `connect-fleet-over-tailnet`, and `key-fleet-by-host` are archived. `package-user-programs` owns activation idempotence and PostgreSQL data ownership. `derive-windows-check-from-declaration` owns the Windows renderer and check. `simplify-repository-documentation` owns the final documentation consolidation.
