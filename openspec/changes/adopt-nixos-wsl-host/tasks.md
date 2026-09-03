## 1. Prepare the Host Definition

- [x] 1.1 Add the `nixos-wsl` input with `inputs.nixpkgs.follows = "nixpkgs"`, and comment why this input follows while `llm-agents` does not.
- [x] 1.2 Add `hosts/korolev/default.nix` that supplies the hostname and username and selects the shared modules.
- [x] 1.3 Expose `nixosConfigurations.korolev` from `flake.nix`.
- [x] 1.4 Create `modules/nixos/default.nix` and confirm that the `moduleImports` check covers the new directory.

## 2. Declare the WSL System Scope

- [x] 2.1 Enable the NixOS-WSL module, set the default user, and declare the WSL runtime settings.
- [x] 2.2 Declare the Numtide substituter and its trusted public key in `nix.settings`.
- [x] 2.3 Enable flakes and the pinned Nix features that the repository commands require.
- [x] 2.4 Disable `getty@tty1.service`.
- [x] 2.5 Enable `programs.nix-ld` for prebuilt project executables.
- [x] 2.6 Confirm that the configuration declares no SSH server, no other inbound service, and no secret.
- [x] 2.7 Declare a rootless container runtime with Docker command compatibility.
- [x] 2.8 Confirm that the runtime needs no nested virtualization and exposes no listening service.
- [x] 2.9 Enable zsh at system scope and declare it as the login shell for the declared user.
- [x] 2.10 Declare `Europe/Vienna` as the host time zone.
- [x] 2.11 Declare `de_AT.UTF-8` for the `LC_TIME` and `LC_MEASUREMENT` locale categories.
- [x] 2.12 Remove the duplicate `isNormalUser`, `extraGroups`, and `EDITOR` declarations that NixOS-WSL or `programs.nano` already makes.

## 3. Declare the WSL User Scope

- [x] 3.1 Import Home Manager as a NixOS module with the same options the Darwin host uses.
- [x] 3.2 Select the portable user modules and confirm that no Darwin-only module is reachable.
- [x] 3.3 Declare `johann.glock@scch.at` as the global Git email for this host.
- [x] 3.4 Declare the GitHub no-reply address for personal repository trees with a conditional Git include.
- [x] 3.5 Set `EDITOR` for this host to a program that the host actually provides.
- [x] 3.6 Exclude `zed` and the Zed part of `catppuccin` from the WSL host, and record that the Windows layer owns the editor.
- [x] 3.7 Confirm that `reconcileHerdrOmp` and `verifyPersonalOmp` run as activation steps in the correct order.
- [x] 3.8 Correct the conditional-include comment to state that a repository outside the personal trees uses the work email.

## 4. Add Deterministic Checks

- [x] 4.1 Add a check that builds `nixosConfigurations.korolev.config.system.build.toplevel`.
- [x] 4.2 Add a check that builds the complete portable user-scope set for `x86_64-linux`.
- [x] 4.3 Add a check that asserts the host declares the Numtide substituter and trusted key.
- [x] 4.4 Add a check that asserts the host configuration declares no SSH server and no secret.
- [x] 4.5 Confirm that the retained `personalOmpShape`, `personalOmpVerification`, and `herdrOmpReconciliation` checks still pass on `x86_64-linux`.
- [x] 4.6 Add a check that asserts the host declares the container runtime, exposes no socket, and needs no nested virtualization.
- [x] 4.7 Add a check that asserts the declared login shell is the shell that the portable module set configures.

## 5. Provision the Host Side by Side

- [x] 5.1 Build the tarball inside the current Ubuntu distribution from the reviewed revision.
- [x] 5.2 Import the distribution while `Ubuntu-26.04` stays registered, without elevation.
- [x] 5.3 Confirm that systemd is process 1 and that the declared user owns the session.
- [x] 5.4 Clone the published revision under the tree that the conditional include names, then run `nixos-rebuild switch --flake .#korolev` with no other distribution running and with `user@1000.service` active.
- [ ] 5.5 Confirm that Herdr reports `omp: current` and that local verification succeeds.
- [ ] 5.6 Confirm that an unprivileged build reports no ignored `trusted-public-keys` warning.
- [x] 5.7 Re-activate the same revision and confirm that nothing changes and no duplicate entry appears.
- [ ] 5.8 Confirm that name resolution, both substituters, and GitHub authentication work with the corporate VPN connected.
- [x] 5.9 Confirm with `getent passwd` and a new session that the login shell is the declared shell.
- [x] 5.10 Confirm that the prompt, the shared history, and the completion behavior are active in that session.
- [x] 5.11 Confirm the time zone with `date`, and confirm the time and measurement categories with `locale`.

## 6. Prove the Runtime Behavior

- [ ] 6.1 Authenticate the OpenAI and Anthropic providers on the new host without copying any state.
- [x] 6.2 Run the real-session smoke in a disposable repository and confirm the plugin path under `/nix/store`.
- [x] 6.3 Confirm that the personal policy is active and that `personal_commit` is registered.
- [x] 6.4 Confirm that the `personal_commit` preview changes no repository state.
- [x] 6.5 Confirm the Git identity in a personal tree, outside a personal tree, in a fresh clone, and in a clone directly under `~/src`.
- [ ] 6.6 Activate a deliberately failing generation and confirm that the previous generation stays selectable.
- [ ] 6.7 Confirm that rollback changes no OMP-owned authentication, configuration, session, history, or database.
- [x] 6.8 Run a container image through the Docker command name and confirm that it starts and exits with its own status.

## 7. Remove the Superseded Implementation

- [ ] 7.1 Delete `packages/personal-omp-wsl.nix`, `packages/bootstrap-omp-on-wsl.nix`, and `packages/bootstrap-omp-on-wsl-tests.nix`.
- [ ] 7.2 Remove the `wslOmpEnvironment` and `bootstrapOmpOnWslCommand` checks and the `bootstrap-omp-on-wsl` application and package outputs.
- [ ] 7.3 Confirm that no alias, wrapper, or documentation preserves the retired command.
- [ ] 7.4 Set the NixOS profile as the Windows Terminal default and confirm that it opens in the Linux home directory.
- [ ] 7.5 Remove the `Ubuntu-26.04` distribution only after every gate in sections 5 and 6 passes.
- [ ] 7.6 Confirm after the removal that the host reports a running system with no failed unit.

## 8. Update the Documentation

- [ ] 8.1 Rewrite `docs/operations/wsl-omp-bootstrap.md` for import and NixOS activation, and delete the package-manager and Nix-installer sections.
- [ ] 8.2 Document the side-by-side cutover, generation rollback, and distribution rollback.
- [ ] 8.3 Record the release evidence, including the NixOS release and the locked revision.
- [x] 8.4 Update `README.md` for the second host and the two entry-point kinds.
- [ ] 8.5 Add a dated architecture decision entry that reverses the profile-entry decision and states the three-layer ownership model.
- [ ] 8.6 State that the operator holds durable local administrator credentials and that the declarative layer deliberately does not use them.
- [ ] 8.7 State in the runbook that a personal repository clone belongs under the tree that the conditional include names.

## 9. Verify the Complete Change

- [ ] 9.1 Run `nix fmt -- --fail-on-change`.
- [ ] 9.2 Run `nix flake check --print-build-logs` on `x86_64-linux` and inspect the new host checks.
- [ ] 9.3 Run `nix build .#darwinConfigurations.macbook-pro.system` and confirm that the Darwin host still builds.
- [ ] 9.4 Run `nix run .#check-darwin-build-plans`.
- [ ] 9.5 Run `openspec validate adopt-nixos-wsl-host --strict`.
- [ ] 9.6 Review the final diff by host, module, check, deletion, and documentation, and confirm that no module declares a Windows container product.
