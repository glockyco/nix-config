## 1. Cut Over Executable Ownership

- [x] 1.1 Add the official `can1357/tap` tap and `can1357/tap/omp` formula to the Darwin Homebrew declaration, and verify the evaluated Brewfile contains one OMP formula.
- [x] 1.2 Change `packages/personal-omp.nix` to accept one explicit runtime executable path, and verify its wrapper embeds that path plus the existing immutable plugin flags.
- [x] 1.3 Pass `/opt/homebrew/bin/omp` on Darwin and one dedicated user-local binary path on NixOS/WSL, and verify both host evaluations select the intended path.
- [x] 1.4 Remove every host installation, passthrough value, assertion, and wrapper reference for the Nix-packaged OMP executable, and verify a repository search finds no obsolete `upstreamOmp` or `llmAgents.omp` consumer.
- [x] 1.5 Keep `llm-agents` only for Herdr and OpenSpec, and verify both packages still resolve on Darwin and NixOS/WSL.

## 2. Preserve Wrapper and Windows Integration

- [x] 2.1 Make the wrapper fail with an actionable error when its platform executable is absent, and verify deterministic tests cover the expected Darwin and WSL paths.
- [x] 2.2 Expose the local verifier as an explicit command outside activation, make it exercise the platform executable with the immutable plugin, and verify its success and missing-binary cases.
- [x] 2.3 Update package-shape checks to use an explicit stub executable instead of a Nix OMP package, and verify the checks still reject missing plugin flags, mutable paths, and duplicate command payloads.
- [x] 2.4 Preserve Windows Zed's `wsl.exe` route to the wrapped `omp acp` command, and verify the rendered Windows settings contain no native Windows OMP command or fallback.
- [x] 2.5 Keep the Home Manager profile ahead of Homebrew in fresh Darwin shells, and verify bare `omp` resolves to the Nix-managed wrapper after activation.

## 3. Define Manual Install and Recovery Operations

- [x] 3.1 Document the Darwin install, explicit update, version check, and previous-release recovery commands for the official Homebrew formula, and verify each command names the official tap.
- [x] 3.2 Document the WSL install and update command with the official installer in `--binary` mode and the wrapper's dedicated `PI_INSTALL_DIR`, and verify the command cannot select a source build.
- [x] 3.3 Document WSL previous-release recovery with an explicit oh-my-pi release tag, and verify it writes the same dedicated executable path.
- [x] 3.4 Update WSL bootstrap ordering so the official binary exists before wrapper verification, and verify the procedure still preserves OMP-owned mutable state.
- [x] 3.5 Update activation and rollback guidance to separate Nix generation rollback from platform-owned OMP recovery, and verify neither activation path claims to update or downgrade OMP.

## 4. Update Contracts and Architecture

- [x] 4.1 Sync the `personal-omp-workstation` delta into the main specification and verify every modified requirement retains its complete scenarios.
- [x] 4.2 Sync the `dependency-update-automation` delta into the main specification and verify OMP has one update owner on each host.
- [x] 4.3 Update the architecture ownership, activation, verification, rollback, acceptance, and decision sections, and verify no current-state text calls the OMP executable immutable or Nix-managed.
- [x] 4.4 Update the dependency runbook so `llm-agents` updates cover Herdr and OpenSpec but not OMP, and verify it contains no OMP-specific `flake.lock` update instruction.
- [x] 4.5 Update repository guidance and the Windows runbook where their current behavior changes, and verify the Windows host still uses one oh-my-pi instance inside NixOS/WSL.

## 5. Verify the Repository

- [x] 5.1 Run `openspec validate manage-omp-with-homebrew --strict` and resolve every contract or task-numbering error.
- [x] 5.2 Run `nix fmt -- --fail-on-change` and verify no formatting change remains.
- [x] 5.3 Run `nix flake check --print-build-logs` and verify all Darwin, NixOS/WSL, Windows-document, wrapper, and OpenSpec checks pass.
- [x] 5.4 Run `nix run .#check-darwin-build-plans` and verify the Darwin closure reaches no prohibited source-built dependency.
- [x] 5.5 Build `.#darwinConfigurations.macbook-pro.system` and `.#nixosConfigurations.korolev.config.system.build.toplevel`, and verify both host closures complete.
- [x] 5.6 Build `.#windows-configuration` and verify its Zed settings still invoke `omp acp` through the NixOS distribution.

## 6. Activate and Prove the Cutover

- [x] 6.1 After review and merge, install the official Darwin OMP formula, run `darwin-switch`, and verify the wrapper reports the Homebrew OMP version, immutable plugin path, and current Herdr status.
- [x] 6.2 Start a fresh wrapped Darwin OMP session and verify the plugin source path, personal policy, and harmless `personal_commit` preview.
- [ ] 6.3 On `korolev`, install the official prebuilt OMP binary, activate the reviewed NixOS generation, and verify the wrapper reports the user-local executable version, immutable plugin path, and current Herdr status.
- [ ] 6.4 Start OMP from Windows Zed and a fresh WSL terminal, and verify both use the same wrapped oh-my-pi environment without a native Windows installation.
- [ ] 6.5 Exercise the documented previous-release recovery on each host or a disposable equivalent, and verify Nix generation rollback is not required to change the OMP version.
