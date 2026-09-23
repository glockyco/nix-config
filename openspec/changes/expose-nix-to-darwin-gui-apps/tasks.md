## 1. Host configuration

- [x] 1.1 Configure the persistent user-domain `PATH` with standard macOS paths and the stable Nix profile directory; verify activation renders `launchctl config user path` with the exact value.
- [x] 1.2 Run `nix` from a process with only the proposed persistent GUI `PATH` and verify the executable resolves without shell startup or repository hook changes.

## 2. Release acceptance

- [x] 2.1 Validate this change strictly, run `nix fmt -- --fail-on-change` and `nix flake check --print-build-logs`, and build the Darwin system; verify every pre-activation gate passes.
- [ ] 2.2 After review and merge, record the prior user-domain `PATH` and its rollback command, activate the Mac generation, and reboot; verify Fork runs the real repository pre-push hook without a missing-`nix` error, and record the result with this change.
