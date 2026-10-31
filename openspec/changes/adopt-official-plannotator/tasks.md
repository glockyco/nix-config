# Tasks

## 1. Configuration and documentation

- [x] 1.1 Add the chezmoi modify template for `~/.plannotator/config.json`. Verify that it creates the file with sharing off and keeps other keys of an existing file.
- [x] 1.2 Document the plugin installation in the README, refer to it from the Korolev runbook and add its advancement to the update runbook. Verify that `omp plugin upgrade` leaves an npm plugin at its version, as the README says.
- [x] 1.3 Run the formatter, both OpenSpec validations and `nix flake check`. Verify that they pass.

## 2. Hosts

- [ ] 2.1 On the Mac, install the plugin with the README command and apply chezmoi. Verify `omp plugin list` and the configuration file.
- [ ] 2.2 After omp-agent-setup 0.10.0, verify in a fresh OMP session on the Mac that `/plannotator-annotate` and `/plannotator-last` come from Plannotator's plugin.

## Workflow follow-up

- Install the plugin on Korolev in a Tern desktop session, apply chezmoi and check the same commands.
- Archive the change after both hosts run it.
