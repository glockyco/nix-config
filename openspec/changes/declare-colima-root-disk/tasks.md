# Tasks

## 1. Root disk declaration

- [x] 1.1 Add a required `rootDisk` of type positive integer, described as the Colima virtual-machine root disk in GiB, to `host.darwin.containerProfile` in `modules/fleet/host.nix`. Declare `rootDisk = 20` for the Mac in `home/.chezmoidata/hosts.toml` and render it in `home/dot_config/colima/default/colima.yaml.tmpl`, and verify the shared-facts check accepts the declaration.
- [x] 1.2 Compare `rootDisk` in `checks/chezmoi-container-check.py` and require it to be positive, and verify `nix flake check` passes on the Mac.
- [x] 1.3 State in `docs/operations/container-runtime.md` that the root disk keeps the declared size and that changing it requires recreating the profile, and verify the format check passes.

## 2. Acceptance

- [ ] 2.1 Verify that the PR's macOS, Linux and OpenSpec CI checks pass.
- [ ] 2.2 On the Mac, run `darwin-switch` from the PR branch while the owner types the password, and verify that the switch succeeds and `chezmoi diff` is empty afterwards.
- [ ] 2.3 With no container running, stop and start Colima, and verify that it starts without a disk-shrinking error and reports the declared disk sizes.
