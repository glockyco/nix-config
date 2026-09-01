## 1. WSL Package Contract

- [ ] 1.1 Add one `x86_64-linux` environment package containing the existing wrapped `omp`, OpenSpec, Herdr reconciliation, and local verification commands; verify the package exposes only the four owned commands and all paths resolve to the locked closures.
- [ ] 1.2 Export `bootstrap-omp-on-wsl` as an `x86_64-linux` flake application that consumes the combined environment package; verify `nix flake show` exposes the package and application on Linux without changing Darwin outputs.

## 2. Transactional Bootstrap

- [ ] 2.1 Implement fail-closed WSL 2 and `x86_64-linux` detection before profile mutation; verify command tests reject native Linux, WSL 1, and unsupported architecture fixtures without invoking the profile command.
- [ ] 2.2 Implement clean installation and same-revision re-entry for one named user-profile entry; verify temporary-profile tests resolve `omp` and `openspec` after installation and produce no duplicate entry after re-entry.
- [ ] 2.3 Implement reviewed-revision replacement without updating `flake.lock` or unrelated profile entries; verify tests select the new locked closure while preserving unrelated entries and leaving the checkout unchanged.
- [ ] 2.4 Run the packaged Herdr reconciliation and verifier after the profile switch, with automatic profile rollback on failure; verify success, stale integration, reconciliation failure, verification failure, prior-generation restoration, and clean-install cleanup paths.
- [ ] 2.5 Preserve WSL-local OMP state across every bootstrap path; verify temporary-home tests retain configuration and database sentinels and permit only Herdr's supported generated-extension mutation.

## 3. Operator Procedure

- [ ] 3.1 Add the WSL OMP bootstrap runbook with Windows Terminal Stable installation or update, the generated Ubuntu WSL 2 default profile, exact PowerShell prerequisites, Linux-user and Nix setup, repository acquisition, the one post-Nix command, update re-entry, unsupported-platform behavior, and recovery; verify every repository-owned command matches an exported flake output and every Windows setting remains a manual operator action.
- [ ] 3.2 Add deterministic verification and real-session smoke instructions that record Windows Terminal, Windows, WSL, distribution, architecture, and locked-revision evidence; verify the smoke uses normal terminal settings, documents OMP's `Alt+V`, `Ctrl+Q`, and `Alt+Shift+V` fallbacks, and checks the `/nix/store` plugin path, personal policy, registered `personal_commit`, and a non-mutating preview.
- [ ] 3.3 Update the canonical OMP architecture with the delivered WSL ownership and mutable-state boundaries; verify it keeps Windows application installation and management, employer policy, provider authentication, project toolchains, and game workflows outside repository ownership.

## 4. Repository Verification

- [ ] 4.1 Run the focused `x86_64-linux` environment-package and bootstrap command checks and verify all package, state-machine, rollback, and state-preservation scenarios pass.
- [ ] 4.2 Run `openspec validate bootstrap-omp-on-wsl --strict`, `nix fmt -- --fail-on-change`, and `nix flake check --print-build-logs`; verify every command exits successfully.
- [ ] 4.3 Run `nix run .#check-darwin-build-plans` and `nix build .#darwinConfigurations.macbook-pro.system`; verify WSL additions do not change the supported Darwin build-plan boundary or break the existing host.

## 5. WSL Acceptance

- [ ] 5.1 On the new Windows machine, update Windows Terminal Stable, make its Ubuntu WSL 2 profile the default, follow the runbook from the manual prerequisite boundary, and run `nix run .#bootstrap-omp-on-wsl`; verify the profile starts in the Linux home directory and the installed commands, current Herdr integration, and deterministic verifier succeed without provider authentication.
- [ ] 5.2 Authenticate interactively, start a fresh wrapped OMP session from Windows Terminal Stable in a disposable WSL repository, and complete the recorded real-session smoke without forced terminal protocol variables; verify the recorded terminal version, immutable plugin, personal policy, documented fallback chords, and `personal_commit` preview before accepting WSL support.
