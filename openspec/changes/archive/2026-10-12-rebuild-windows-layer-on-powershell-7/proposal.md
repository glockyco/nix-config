# Proposal

## Why

The Windows layer repeats installation and convergence logic inside 61 WinGet DSC resources and takes about seven minutes for a no-op apply. A single PowerShell 7 engine with declarative JSON removes the process overhead and makes the live lessons enforceable with proportional tests.

## What Changes

- Replace embedded test/set scripts with one schema-validated Windows application/settings data file and one PowerShell 7 module.
- Batch installed WinGet discovery once before testing. Only after installs or updates, refresh it once to verify changed packages together. Provide read-only drift reporting with nonzero status and an idempotent apply.
- Pin Bun 1.3.13 for omp-agent-setup and OpenSpec 1.14.0 for its reusable workflow. Other applications default to present without upgrades or downgrades. Reviewed archive and npm integrity locks select installation payloads, not a reason to downgrade existing installations.
- Preserve all 61 application/settings resource behaviors and chezmoi file ownership, including typed taskbar visibility. Restart Explorer only when taskbar visibility changes. The prohibition covers pinned-application lists, not visibility.
- Keep the Neo and Zen policy Administrator scripts separate. TeX Live, Tern, OMP, authentication and network cutovers remain explicit owner operations.
- Replace the two-host DSC CI gate with one pwsh-only Windows job using Pester, Test-Json, PSScriptAnalyzer, privilege invariants and applicable shared formatting.
- Add a minimal Windows PowerShell 5.1 bootstrap that installs pwsh, Git and chezmoi and hands over without applying workstation resources. Port native development tooling and lefthook dispatch to pwsh in their own pre-parity commit.
- BREAKING: switch chezmoi to the hash-protected engine and pwsh, and remove the WinGet Configuration document, DSC schemas/checker, mutation fixtures, installer doubles, Desktop preludes and legacy CI legs in this PR. Live parity and chezmoi apply on the PR branch are owner-run pre-merge gates.

## Capabilities

### New Capabilities

None. The existing workstation and repository-gate boundaries own these behaviors.

### Modified Capabilities

- `windows-workstation-layer`: replace DSC execution, version selection, setting safety and validation contracts with declarative JSON and one PowerShell 7 engine.
- `repository-quality-gates`: use one native PowerShell 7 gate with proportional mocked tests and repo-local test dependencies.

## Impact

Targets the state after `make-korolev-windows-native` is archived, as `retire-korolev-wsl-host` does. Supersedes that change's WinGet document, exact-by-default versions, dual-host schema/parser/fixture and chezmoi interpreter promises. The currently shipped Docker exception takes precedence over the older delta's Docker exclusion. Nix, WSL retirement, tailnet/OpenSSH cutover and macOS are not part of this change.

The PR contains the complete cutover. Porting native development tooling remains its own commit. Git history retains the legacy implementation for source rollback. Before merge, the integrator alone runs the engine dry run and then chezmoi apply on Korolev from the PR branch, accepting zero drift or each named difference and recording post-apply convergence. Agents verify only mocks. The minimal fresh-machine bootstrap is documented in README and the operations runbook.
