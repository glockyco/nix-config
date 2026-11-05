# Tasks

## 1. App Store inventory support

- [x] 1.1 Add typed App Store identity fields, identity assertions and safe login-path diagnostics in modules/fleet/host.nix, with positive and negative fixtures in checks/host-declaration-check.nix. Verify the host declaration check passes.
- [x] 1.2 Derive homebrew.masApps and expose mas in the Darwin desktop role. Extend the shared-facts normalization and desktop inventory gate in flake-modules/checks.nix. Verify the evaluated configuration and host inventory checks match the typed records.
- [x] 1.3 Declare Keynote in home/.chezmoidata/hosts.toml for reading and exporting existing decks. Update README inventory guidance with App Store prerequisites. Verify the evaluated homebrew.masApps contains Keynote = 409183694.

## 2. Integration acceptance

- [x] 2.1 Run strict change validation, both README OpenSpec validations, nix fmt -- --fail-on-change, nix flake check --print-build-logs, nix run .#check-darwin-build-plans and nix build .#darwinConfigurations.macbook-pro.system. Record results without activating the system.
- [ ] 2.2 Commit the verified change on its feature branch using personal_commit. Report the branch, commit, verification results, interactive activation command and App Store prerequisites. Do not push.
