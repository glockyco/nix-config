## 1. Declarative Identity Policy

- [x] 1.1 Broaden Korolev's conditional Git include to `~/src/github.com/`, update its ownership comment, and verify the evaluated Home Manager configuration retains the SCCH global email with the host-wide GitHub condition.
- [x] 1.2 Update the WSL bootstrap guidance to distinguish the GitHub tree from repositories that retain the global SCCH address, and verify the documented command still reports the expected email in this checkout.

## 2. Verification and Deployment

- [x] 2.1 Run `nix fmt -- --fail-on-change` and `nix flake check --print-build-logs`, then verify an isolated generated Git configuration selects the no-reply email for multiple GitHub owners, the SCCH email for an SCCH GitLab repository, and a repository-local email when configured.
- [x] 2.2 After review and merge, activate Korolev with `sudo nixos-rebuild switch --flake .#korolev`, inspect activation output, and verify effective emails in disposable repositories below both host trees, including a repository-local override.
- [x] 2.3 Record the verification evidence, mark every completed task, run `openspec validate broaden-github-git-identity --strict`, and archive the change only after every acceptance gate passes.
