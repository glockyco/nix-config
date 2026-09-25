## 1. Change the version policy

- [ ] 1.1 In `packages/windows-configuration/applications.nix`, set Zen's `versionPolicy` to `self-updating` and remove its version. Render the document and confirm that `package browser` has `useLatest: true`, no version, and the elevated security context.
- [ ] 1.2 In `packages/windows-configuration-check`, add the browser role to `SELF_UPDATING`, change its `FIXED_ROLES` policy to `self-updating`, and adjust the test fixtures. Run the focused Windows configuration check.
- [ ] 1.3 Name Zen with the self-updating applications in `docs/operations/wsl-omp-bootstrap.md`. Review the procedure for elevation accuracy.

## 2. Validate and review

- [ ] 2.1 Run `openspec validate treat-zen-as-self-updating --strict`, `nix fmt -- --fail-on-change`, and `nix flake check --print-build-logs`. Resolve every failure.
- [ ] 2.2 Commit only the change-owned files as one atomic configuration change with a causal commit body.

## 3. Prove Windows behavior

- [ ] 3.1 Run `winget configure test` with the rendered document. Record the installed and catalog Zen versions and the `package browser` result in `evidence.md`. Archive the change after the gate passes.
