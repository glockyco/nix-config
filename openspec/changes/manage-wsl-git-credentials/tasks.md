## 1. Declare the host capability

- [x] 1.1 Enable a NixOS Secret Service provider on Korolev; verify the evaluated D-Bus registration and package closure.
- [x] 1.2 Configure the Nix-managed Git Credential Manager for Korolev's Git; verify the evaluated Home Manager Git settings and preserve GitHub's `gh` helper.

## 2. Document enrollment

- [x] 2.1 Document collection unlock, token enrollment, and recovery in the existing WSL operations guide; verify instructions against the configured command paths.

## 3. Validate and activate

- [x] 3.1 Validate the OpenSpec change and run the repository's Nix formatting and flake gates; verify the rendered Windows application set is unchanged.
- [ ] 3.2 Review and commit the change; activate the committed Korolev configuration under the README release procedure, keeping the previous generation.
- [ ] 3.3 Remove the paper repository's temporary cache override; enroll the token in Secret Service without exposing it and verify a non-interactive Overleaf Git lookup after a credential-cache exit.
