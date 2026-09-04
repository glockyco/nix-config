## 1. Record the Structural Baseline

- [ ] 1.1 Record the parent commit, `flake.lock` checksum, and both system `toplevel.drvPath` values in `baseline.md`. Force one `system.configurationRevision` through `extendModules`, and confirm that both recorded expressions evaluate twice to the same paths.
- [ ] 1.2 Record the current Windows configuration output hash and the current Air SSH, batch, SMB, Colima, screenshot, Git, Nix, and SOPS evaluated values. Confirm that each command in `baseline.md` succeeds before editing.

## 2. Extend the Typed Host Declaration

- [ ] 2.1 Add typed host options for display identity, time zone, locale, checkout and screenshot paths, and Git identity. Add assertions for required non-empty values, and confirm that a temporary host which omits each required value fails with its option path.
- [ ] 2.2 Add the typed Darwin application inventory with optional Dock positions. Reject duplicate casks, application paths, and positions, and confirm each rejection with a temporary duplicate that is then reverted.
- [ ] 2.3 Add typed Colima capacity and mount values with positive-number assertions. Confirm that a temporary zero CPU, memory, or disk value fails evaluation, then revert the probe.
- [ ] 2.4 Add the typed Air endpoint, batch, remote Docker, SMB share, and mount-point values. Confirm that the evaluated `macbook-pro` declaration contains one value for each fact and no `.local` destination.
- [ ] 2.5 Move the values into `hosts/macbook-pro/default.nix` and `hosts/korolev/default.nix`. Confirm that no platform or shared module retains a machine name, user name, Git author, GitHub no-reply address, checkout path, screenshot path, Air account, or Colima capacity literal.

## 3. Separate Baselines from Roles

- [ ] 3.1 Create `modules/roles/darwin/{desktop,postgresql,container-client,air-client}/default.nix` and `modules/roles/nixos/wsl-workstation/default.nix`. Update the module-import check scope, and confirm it rejects one temporary unlisted sibling before the probe is reverted.
- [ ] 3.2 Reduce `modules/darwin/default.nix` and `modules/nixos/default.nix` to platform baselines. Make each host import its roles explicitly, and confirm that no platform baseline imports a role.
- [ ] 3.3 Move the desktop system and user modules into the Darwin desktop role without content changes. Confirm that both pinned-revision system derivation paths equal the baseline after the move.
- [ ] 3.4 Move PostgreSQL, Colima client, and Air client ownership into their Darwin roles. Move WSL integration and rootless containers into the NixOS WSL role. Confirm both pinned-revision paths after each role cutover.
- [ ] 3.5 Evaluate a temporary Darwin host that imports only the baseline. Confirm it declares no Homebrew casks, persistent Dock entries, PostgreSQL service, Colima profile, or Air endpoint, then remove the probe.
- [ ] 3.6 Search shared modules for platform conditionals and platform-owned options. Move every remaining case to its role, and confirm that the search reports none.

## 4. Remove Duplicate Identity and Path Declarations

- [ ] 4.1 Render the system screenshot default and Home Manager directory from `host.paths.screenshots`. Change the value temporarily, confirm both evaluated consumers change, then revert it.
- [ ] 4.2 Render Git author and email policy from `host.git`. Derive the personal Git include from the evaluated ghq root, and confirm that changing the root changes the include without another edit.
- [ ] 4.3 Generate Homebrew casks and Dock entries from `host.darwin.applications`. Compare the generated lists with the baseline, and confirm that one temporary application edit changes both applicable consumers before it is reverted.
- [ ] 4.4 Pass `host.paths.configurationCheckout` and the pinned `darwin-rebuild` executable to the packaged `darwin-switch`. Confirm that its script contains the declared store executable and no literal checkout or PATH lookup.
- [ ] 4.5 Move the nix-homebrew profile fragment from the portable shell module to the Darwin desktop user module. Derive it from `config.home.profileDirectory`, and confirm both pinned-revision system paths remain equal to the baseline.
- [ ] 4.6 Move `EnterprisePoliciesEnabled` to the Darwin Zen module and delete the Windows `removeAttrs` compensation. Confirm that the Windows output hash remains equal to the baseline.

## 5. Make the Air Contract Declaration-Driven

- [ ] 5.1 Render the interactive and batch SSH aliases from `host.remote.air`. Confirm that both aliases share the evaluated MagicDNS host and user while only the batch alias carries the non-interactive settings.
- [ ] 5.2 Make `remoteDockerExecutable` a required argument of `air-batch-check`. Pass it from the Air client role, remove the `AIR_BATCH_DOCKER` environment contract, and confirm the existing command tests pass with an overridden argument.
- [ ] 5.3 Make `air-batch-config-check` derive the destination and account from the evaluated SSH settings. Confirm that a temporary host or user change needs no check edit and that one mismatched batch alias fails the check.
- [ ] 5.4 Replace the Finder-selected `/Volumes` path with the declared mount point and `mount_smbfs -N`. Confirm on the Mac that the Air share mounts at that exact path without a prompt and that `~/Air` resolves into it.
- [ ] 5.5 Re-run the documented batch acceptance on the reachable Air. Confirm success, remote failure propagation, protocol transfer, and the declared remote Docker executable.

## 6. Unify Nix Policy

- [ ] 6.1 Add one shared Nix policy for the pinned registry, disabled channels, garbage collection, and store optimisation. Add thin Darwin and NixOS adapters, and confirm that both evaluated configurations carry the same policy values.
- [ ] 6.2 Keep the Darwin user in `trusted-users` and replace its comment with the remote-builder unsigned-input rationale. Confirm that `korolev` completes one Darwin build through the tailnet after the comment-only edit.
- [ ] 6.3 Remove the explicit NixOS `programs.nano.enable` and normal-user home declarations. Confirm against the pinned module defaults and evaluated `korolev` configuration that Nano stays enabled and the home path stays `/home/<user>`.
- [ ] 6.4 Activate `korolev` after the intentional Nix-policy change. Confirm the registry pin, disabled channel lookup, garbage-collection timer, optimisation timer, and retained generations match the declaration.

## 7. Derive Container and Secrets Configuration

- [ ] 7.1 Render Colima CPU, memory, disk, and mounts from the host declaration and its architecture from `pkgs.stdenv.hostPlatform.qemuArch`. Confirm that the generated profile keeps every baseline value.
- [ ] 7.2 Replace the two Cloudflare direnv blocks with one Nix helper and `xdg.configFile`. Confirm that both generated functions are byte-identical to the baseline.
- [ ] 7.3 Generate an offline age recovery key on encrypted removable storage. Add only its public recipient to `.sops.yaml`, and confirm that the private key is absent from the repository and both hosts.
- [ ] 7.4 Re-encrypt every file under `secrets/` for the Mac and recovery recipients, then remove `encrypted_regex`. Confirm that the Mac key and the offline recovery key each decrypt every file before replacing the prior ciphertext.
- [ ] 7.5 Add `packages/secret-encryption-check.nix` and its fixture tests. Register the command and tree checks on every system, and confirm that the encrypted fixture passes while nested plaintext mapping and list fixtures fail with their scalar paths.
- [ ] 7.6 Prove the repository check rejects a temporary plaintext scalar under `secrets/`, observe the file and scalar path in the failure, then revert and re-encrypt the probe.

## 8. Verify Intentional and Structural Changes

- [ ] 8.1 Confirm that every behavior-preserving step leaves both pinned-revision system derivation paths equal to `baseline.md`. For any difference, run `nvd diff`, explain the cause, and remove unintended closure changes.
- [ ] 8.2 Confirm the intentional differences only: NixOS maintenance options and units, the stable Air mount path, the parameterized batch Docker path, and re-encrypted secret files. Record their evaluations and live results in `baseline.md`.
- [ ] 8.3 Run `nix fmt -- --fail-on-change`.
- [ ] 8.4 Run `nix flake check --all-systems --print-build-logs` on `korolev` through the configured Darwin remote builder.
- [ ] 8.5 Run `nix flake check --print-build-logs`, `nix run .#check-darwin-build-plans`, and `nix build .#darwinConfigurations.macbook-pro.system` on the Mac.
- [ ] 8.6 Run `openspec validate separate-platform-baseline-from-roles --strict`.
- [ ] 8.7 Review the final diff by host option, baseline, role, generated declaration, secret, and check. Confirm that every old literal, duplicate list, compatibility compensation, and obsolete path is removed.

## 9. Documentation

- [ ] 9.1 Add a dated architecture decision for platform baselines, explicit host roles, declaration-owned machine facts, and complete secret encryption.
- [ ] 9.2 Update the README module and host layout rows. Name the role directories and the typed host declaration, and confirm `nix fmt -- --fail-on-change README.md` passes.
