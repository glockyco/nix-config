## Scheduling — 2026-09-26

The owner scheduled this change after plan review. It runs at position 3, after `derive-windows-check-from-declaration`. On 2026-09-26 the owner authorized implementation after changes 1 and 2 are implemented and pass the Mac gates, while their Korolev, CI, and Windows owner gates are pending. Changes 1 through 5 archive in order, each after its owner gates pass.

## 1. Record behavior before role moves

- [x] 1.1 Record the parent commit and `flake.lock` checksum in `baseline.md`. Force one `system.configurationRevision` through `extendModules` and `lib.mkForce`; evaluate each host's `toplevel.drvPath` twice and record equal paths.
- [x] 1.2 Build the completed change 2 Windows output. Record its store path and the names and SHA-256 hashes of all 19 rendered files in `baseline.md`. Evaluate Air SSH, SMB, batch, Colima, screenshot, Git, Nix, PostgreSQL `dataDir`, and SOPS values; record successful commands and values.

## 2. Extend standalone typed host declarations

- [ ] 2.1 Extend `modules/fleet/host.nix` with typed display identity, time zone, locale, checkout and screenshot paths, and Git identity. Set values only in `hosts/<name>/host.nix`. Probe each required option omission; record the failing option path and restored evaluations.
- [ ] 2.2 Add typed `host.darwin.applications` records with optional cask and Dock position. Probe duplicate non-null casks, application paths, and positions; record each expected failure and remove each probe.
- [ ] 2.3 Add positive Colima CPU, memory, and disk values and typed mounts to the Mac host declaration. Probe zero values; record the expected errors and restored evaluation.
- [ ] 2.4 Keep `hosts/<name>/default.nix` for imports and per-machine Home Manager wiring. Confirm the registry evaluates each standalone `host.nix` without evaluating either full host configuration.

## 3. Select platform roles explicitly

- [ ] 3.1 Create `modules/roles/darwin/{desktop,postgresql,container-client,air-client}/default.nix` and `modules/roles/nixos/wsl-workstation/default.nix`. Extend the module-import check for these directories; prove one temporary unlisted sibling fails, then remove it.
- [ ] 3.2 Reduce `modules/darwin/default.nix` and `modules/nixos/default.nix` to common platform imports. Move each role's system and Home Manager imports under its role. Record that the Mac imports four roles, Korolev imports `wsl-workstation`, and neither baseline imports a role.
- [ ] 3.3 Move the desktop system and user modules without changing behavior. Compare both pinned-revision `toplevel.drvPath` values to section 1 after each cutover; record any `nvd diff` and remove unintended changes.
- [ ] 3.4 Move the PostgreSQL service and its idempotent `install -d` activation into the Darwin PostgreSQL role. Confirm evaluated `services.postgresql.dataDir` remains `/var/lib/postgresql/17`, package remains PostgreSQL 17, and both pinned-revision derivation paths remain unchanged.
- [ ] 3.5 Move Colima into `container-client`, Air integration into `air-client`, and WSL integration and rootless containers into `wsl-workstation`. Compare both pinned-revision paths after each behavior-preserving move.
- [ ] 3.6 Evaluate a temporary Darwin host with only its baseline. Record that it has no desktop casks or Dock applications, PostgreSQL service, Colima profile, or Air aliases. Remove the probe.
- [ ] 3.7 Search shared modules for platform branches and machine-only options. Move each remaining case to its owner; record a clean search and both host evaluations.

## 4. Derive durable values from one host fact

- [ ] 4.1 Render the system screenshot setting and Home Manager directory from `host.paths.screenshots`. Change the value temporarily; record both changed evaluated consumers and restore the declaration.
- [ ] 4.2 Render Git author and email policy from `host.git`. Derive Korolev's personal include from evaluated `programs.git.settings.ghq.root`; change that root temporarily, observe the include change, and restore it.
- [ ] 4.3 Generate casks and ordered Dock apps from `host.darwin.applications`; keep spacer and empty `persistent-others`. Compare both generated lists with section 1; change one app record temporarily and observe both consumers.
- [ ] 4.4 Feed `host.paths.configurationCheckout` and the pinned `darwin-rebuild` executable into `darwin-switch`. Inspect its generated script for the declared checkout and store executable and absence of a `PATH` lookup.
- [ ] 4.5 Move the nix-homebrew profile adjustment to the Darwin desktop user module. Confirm the rendered path comes from `config.home.profileDirectory` and both pinned-revision derivations match section 1.
- [ ] 4.6 Move `EnterprisePoliciesEnabled` into the Darwin Zen module. Delete `removeAttrs` in the renderer at `packages/windows-configuration/`. Build the Windows package, compare every rendered file byte-for-byte with section 1's completed change 2 output, and record equal file hashes.

## 5. Keep Air working as one removable integration

- [ ] 5.1 Move both existing Air SSH aliases, `air-batch-check` installation, the existing SMB mount agent, and `~/Air` link into the Air role's imports. Inspect evaluated SSH, launchd, and Home Manager outputs against section 1; record equal values.
- [ ] 5.2 Keep `AIR_BATCH_DOCKER`, the current remote Docker path interface, and Finder's current numbered `/Volumes` target. Run the package's scoped command fixtures and verify no `host.remote.air` option, stable mount, or new Docker-path derivation appears.
- [ ] 5.3 Split the combined SSH assertion into Air-only `checks/air-batch-config-check.nix` and durable `checks/desktop-batch-config-check.nix`. Preserve all existing desktop host-pin and transport checks. Keep the Air package and tests in `packages/air-batch-check/`. Condition Air package/check wiring in `flake-modules/{packages,checks}.nix` on role selection; prove both checks run with the role and the desktop check remains without it.
- [ ] 5.4 Remove the Air role temporarily with its package directory, Air-only assertion, flake wiring, and `macbook-air` peer entry. Evaluate durable host outputs and checks, including the desktop SSH gate, without Air references. Restore the temporary deletion and record the exact removal set for issue #17.
- [ ] 5.5 Run the documented live Air acceptance when the Air is reachable: successful command, remote status 23, protocol transfer, remote Docker inspection, and SMB link resolution. Record results without changing its mount or Docker command contracts.

## 6. Apply platform policy and secrets

- [ ] 6.1 Declare pinned registry, disabled legacy channels, weekly garbage collection, and weekly store optimisation once with native Darwin and NixOS adapters. Evaluate both hosts and record option values, unit names, and intentional NixOS differences from section 1.
- [ ] 6.2 Keep Darwin `trusted-users` for remote unsigned input paths and correct its comment only if needed. Evaluate that Korolev retains its Darwin remote builder and Darwin retains the trusted SSH user.
- [ ] 6.3 Confirm pinned NixOS defaults for `programs.nano.enable` and a normal user's home, then remove the redundant assignments. Record that Nano remains enabled and Korolev's home remains `/home/<user>`.
- [ ] 6.4 Render Colima resources from the host declaration and architecture from `pkgs.stdenv.hostPlatform.qemuArch`. Update the config check to derive expected resources; record equal generated profile bytes and a changed value in a temporary probe.
- [ ] 6.5 Render both Cloudflare direnv functions with one helper and `xdg.configFile`. Compare both generated shell files byte-for-byte with section 1 and confirm token paths still come from `config.sops.secrets`.
- [ ] 6.6 Re-encrypt each tracked secret with the Mac recipient; decrypt a temporary copy with the Mac key and record success without exposing plaintext. Keep current ciphertext until the final two-recipient proof.
- [ ] 6.7 Add `checks/secret-encryption-check.nix` and fixtures. Recursively reject plaintext data scalars outside SOPS metadata with file and path. Prove nested map and list failures and encrypted-fixture success; wire the check on every system.
- [ ] 6.8 Insert a temporary plaintext scalar under `secrets/`; run the repository check and record the file and scalar path in its failure. Revert the scalar and confirm the check passes.
- [ ] 6.9 Owner: Generate the offline age private key on encrypted offline media and supply only its public recipient. Record the public recipient and confirm the private key is absent from the repository and both hosts.
- [ ] 6.10 Add the owner-supplied public recipient to `.sops.yaml`, re-encrypt all `secrets/*.yaml` for both recipients, and remove `encrypted_regex`. Confirm Mac-key decryption of every file before replacing the prior ciphertext; record only recipients and success, not secret data.
- [ ] 6.11 Owner: Decrypt every final secret file with the offline recovery key. Record per-file success without copying the key or plaintext into the repository.
- [ ] 6.12 Owner: Activate Korolev after the Nix-policy change. Inspect registry lookup, disabled channels, GC and optimisation timers, retained generations, and builder behavior; record observed commands and results.

## 7. Prove release boundaries and update affected documentation

- [ ] 7.1 Compare both pinned-revision system derivations after all behavior-preserving moves. Explain every remaining difference with `nvd diff`; record intentional NixOS Nix policy and SOPS ciphertext differences separately in `baseline.md`.
- [ ] 7.2 Run `nix fmt -- --fail-on-change` and `openspec validate separate-platform-baseline-from-roles --strict`; record both outcomes.
- [ ] 7.3 Run Mac `nix flake check --print-build-logs`, `nix run .#check-darwin-build-plans`, and `nix build .#darwinConfigurations.macbook-pro.system`; record each outcome.
- [ ] 7.4 Owner: Run `nix flake check --all-systems --print-build-logs` on Korolev with the configured Darwin builder. Record the NixOS and remote Darwin results.
- [ ] 7.5 Owner: Activate the Mac with sudo while retaining local recovery access. Check PostgreSQL on `/var/lib/postgresql/17`, role outputs, Air integration, and Nix policy; record observed results.
- [ ] 7.6 Owner: Run `winget configure test` on the Windows work machine against the unchanged rendered document. Record the exit status and Zen resource state; do not run Windows resources from Nix activation.
- [ ] 7.7 Owner: Observe CI on the reviewed revision after an authorized push. Record each platform gate result; do not substitute a local run for CI evidence.
- [ ] 7.8 Update affected README links, `docs/operations/*` procedures, and nearby comments for role selection, Air offboarding, Nix maintenance, and offline SOPS recovery. Check references against the final paths and actual command output.
- [ ] 7.9 Review the final diff by host declaration, baseline, role, generated output, encrypted secret, check, and documentation owner. Record that no old duplicate list, obsolete renderer compensation, or Air artifact remains outside the deletion set.
