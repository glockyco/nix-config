## 1. Declare the Linux User Application

- [ ] 1.1 Create `modules/home/nixos/default.nix` and `modules/home/nixos/ferdium.nix`; add only `pkgs.ferdium` to the Linux user package set. Confirm that neither module declares startup, settings, credentials, or writable profile files.
- [ ] 1.2 Import `../home/nixos` only from the NixOS Home Manager integration. Evaluate both host configurations and confirm that Korolev contains the Ferdium derivation while the Darwin Home Manager package set does not gain it.
- [ ] 1.3 Inspect the evaluated Korolev user and system units, autostart files, and activation script. Confirm that the declaration adds no Ferdium startup mechanism or updater.

## 2. Verify the Reviewed Configuration

- [ ] 2.1 Build Korolev's Home Manager activation package and NixOS system. Inspect the user profile result and confirm that it contains the Ferdium executable and desktop entry from the same Nixpkgs derivation.
- [ ] 2.2 Run `openspec validate add-ferdium-to-korolev --strict`, `nix fmt -- --fail-on-change`, and `nix flake check --print-build-logs`; resolve every failure.
- [ ] 2.3 Review and commit only the Ferdium declaration, specification, and verification changes as one atomic change with a causal commit body.

## 3. Activate and Prove WSLg Behavior

- [ ] 3.1 Activate Korolev from the committed revision with the README command. Inspect the closure diff and activation output, and retain the previous NixOS generation.
- [ ] 3.2 In a fresh Korolev login shell, confirm that `ferdium` resolves from the active Home Manager profile. Compare its reported version with the evaluated `pkgs.ferdium.version`, and confirm that the installed desktop entry names the same executable.
- [ ] 3.3 Launch Ferdium through WSLg and visually confirm that its window renders and accepts interaction. Do not authenticate a service or change account settings for the acceptance check.
- [ ] 3.4 Close Ferdium, start a fresh Korolev shell, and confirm that no Ferdium process starts. Confirm that no repository-owned systemd unit or autostart entry exists.
- [ ] 3.5 Record the package version, output path, activation revision, executable resolution, desktop entry, WSLg observation, and startup result in `evidence.md`. Preserve any existing Ferdium profile and record whether one existed before activation.
- [ ] 3.6 Run the post-activation Korolev verification required by the README. Sync the new capability to the accepted specifications and archive the change only after every acceptance task passes.
