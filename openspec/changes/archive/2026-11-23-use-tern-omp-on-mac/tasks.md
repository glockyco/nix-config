# Tasks

## 1. Select Tern OMP

- [x] 1.1 Update both Mac zsh templates and shell fixtures for Tern OMP precedence while retaining local tools and Tern CLI.
- [x] 1.2 Update both launch-agent commands and their success/failure fixture to use Tern OMP.
- [x] 1.3 Update AGENTS.md and README for Tern installation and updates on both hosts, removing unsupported Mac installer recovery.

## 2. Verify and publish

- [x] 2.1 Validate this change strictly and run the README Mac checks in an isolated branch checkout without activating it.
- [x] 2.2 Demonstrate command resolution from branch-rendered Mac shell files without changing live configuration or removing the old executable.
- [x] 2.3 Open a pull request and wait for green checks. Record results and remaining user activation in the change record.

## Evidence

- The branch shell templates were rendered with chezmoi on the Mac into `~/src/nix-config-mac-tern-omp-shell-probe`, without applying to the real home. SSH-launched zsh with `no_global_rcs` resolved `/Users/glockyco/Library/Application Support/Tern/omp/bin/omp` and reported `omp/19.1.1` in non-interactive, login, interactive and interactive-login modes. Global startup was excluded to test the rendered files independently of the live generation.
- In the isolated Mac checkout at `~/src/nix-config-mac-tern-omp`, all README Mac commands passed: `nix fmt -- --fail-on-change`, active and archived strict OpenSpec validation, `nix flake check --print-build-logs`, `nix run .#check-darwin-build-plans`, and `nix build .#darwinConfigurations.macbook-pro.system`. OpenSpec reported 22 active items and 64 archived changes passed. The build-plan check examined 66 outputs without a forbidden source build. Darwin flake checks included the updated chezmoi shell and personal-plugin updater fixtures.
- [PR #158](https://github.com/glockyco/nix-config/pull/158) is open and unmerged. The implementation commit passed macOS, Linux, Windows, strict OpenSpec validation and tailnet-policy tests in CI. The policy apply job was skipped as expected for a pull request.
- The old `~/.local/bin/omp` still exists. No system switch, real-home apply or executable deletion was performed.
- After merge, apply the Mac configuration through the README procedure and verify a fresh Tern session. Only then consider removing the old executable as a separate authorized operation.
