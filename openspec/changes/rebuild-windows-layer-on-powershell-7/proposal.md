# Proposal

## Why

The Windows layer repeats installation and convergence logic inside 61 WinGet DSC resources and takes about seven minutes for a no-op apply. A single PowerShell 7 engine with declarative JSON removes the process overhead and makes the live lessons enforceable with proportional tests.

## What Changes

- Replace embedded test/set scripts with one schema-validated Windows application/settings data file and one PowerShell 7 module.
- Batch installed WinGet discovery once per run. Provide read-only drift reporting with nonzero status and an idempotent apply.
- Pin Bun 1.3.13 for omp-agent-setup and OpenSpec 1.14.0 for its reusable workflow. Other applications default to present without upgrades or downgrades. Reviewed archive and npm integrity locks select installation payloads, not a reason to downgrade existing installations.
- Preserve application roles, official archive/npm/font delivery, user settings and chezmoi file ownership. Retire the unsafe taskbar visibility write instead of preserving its StuckRects3 mutation.
- Keep the Neo and Zen policy Administrator scripts separate. TeX Live, Tern, OMP, authentication and network cutovers remain explicit owner operations.
- Replace the two-host DSC CI gate with one pwsh-only Windows job using Pester, Test-Json, PSScriptAnalyzer, privilege invariants and applicable shared formatting.
- BREAKING: after owner-confirmed live parity, switch chezmoi and native development tooling to pwsh and remove the WinGet Configuration document, DSC schemas/checker, mutation fixtures, installer doubles and DSC CI provisioning.

## Capabilities

### New Capabilities

None. The existing workstation and repository-gate boundaries own these behaviors.

### Modified Capabilities

- `windows-workstation-layer`: replace DSC execution, version selection, setting safety and validation contracts with declarative JSON and one PowerShell 7 engine.
- `repository-quality-gates`: use one native PowerShell 7 gate with proportional mocked tests and repo-local test dependencies.

## Impact

Targets the state after `make-korolev-windows-native` is archived, as `retire-korolev-wsl-host` does. Supersedes that change's WinGet document, exact-by-default versions, dual-host schema/parser/fixture and chezmoi interpreter promises. The currently shipped Docker exception takes precedence over the older delta's Docker exclusion. Nix, WSL retirement, tailnet/OpenSSH cutover and macOS are not part of this change.

Implementation first lands alongside the old document and tests. The integrator alone previews/applies on Korolev. The hook/interpreter switch and obsolete-source deletion are a separate final commit after accepted parity. Live acceptance must explain the deliberately retired taskbar setting and changed version policy, not claim literal 61-resource equivalence.
