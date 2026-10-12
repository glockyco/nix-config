# Tasks

## 1. Declarative inventory and engine

- [x] 1.1 Add workstation.json and its Test-Json schema, preserving all 34 application resources and 27 settings including typed taskbar visibility. Name Bun/OpenSpec consumers and reuse reviewed archives/npm integrity locks.
- [x] 1.2 Implement one PowerShell 7 module and explicit dry-run/apply entrypoint with batched WinGet list, exit-code native handling, desired/drift/error output, post-write checks and no downgrade.
- [x] 1.3 Implement WinGet user/machine installation, exact portable-root resolution, Node-adjacent npm, user PATH convergence and Docker's reviewed override.
- [x] 1.4 Implement checksum-verified official ZIP/7z/AltSnap delivery with retained prior directories, npm ci closure and non-destructive user-font installation.
- [x] 1.5 Implement typed/absent HKCU registry values, preserved language/input ordering, Neo prerequisite, stable dark appearance, animation and taskbar visibility with Explorer restart only after actual changes. Keep Administrator tools and manual TeX Live separate.

## 2. Mocked verification and native tooling

- [x] 2.1 Add pinned repo-local PSResourceGet Pester 5/PSScriptAnalyzer setup and analyzer settings. Add and document the minimal PowerShell 5.1 pwsh/Git/chezmoi prerequisite bootstrap without live apply.
- [x] 2.2 Add behavior-level Pester mocks for the snapshot, idempotence, dry-run exits/no writes, native stderr/failure, scope/Pandoc, no downgrade, package roots, archive/npm/font safety, PATH and setting convergence.
- [x] 2.3 Retain schema/parser and privilege invariants for Intune exclusions, machine allowlist, HKCU/prohibited surfaces, Docker arguments and narrow Administrator scripts. Extract surviving checks from the deleted legacy contract checker and migrate distinct chezmoi/lifecycle/hook coverage to pwsh.
- [x] 2.4 Rebase onto the merged affected-job CI selection and use one pwsh-only Windows job for formatting, static checks, Pester mocks and surviving fixtures. Remove all legacy host/provisioning jobs and run local verification against mocks only.
- [x] 2.5 Port Windows dev bootstrap/format/hook/tools/ci and native-windows lefthook dispatch to pwsh in their own commit without changing staged Nix validation.

## 3. Complete cutover PR and pre-merge acceptance

- [x] 3.1 Switch hash-protected chezmoi invocation and persisted interpreter to pwsh in the PR. Hash all engine execution/data/schema/managed-audit inputs and the npm lock before invoking the thin entrypoint.
- [x] 3.2 Delete the WinGet document, vendored DSC schemas, bespoke contract checker, checker-only mutation/installer fixtures, Desktop preludes and WinGet/DSC CI provisioners. Retain distinct surviving source/parser/Administrator/lifecycle tests.
- [x] 3.3 Rewrite the Windows runbook as a short current-state guide and point README and other callers at it. Run complete mocked PowerShell 7/static/format checks and strict OpenSpec validation, then update PR #90. Local `windows/dev/ci.ps1` and `format.ps1 -Check` passed. PR #90 CI passed with `check (windows-latest)` in 2 min 10 s.
- [x] 3.4 Before merge, the integrator runs the engine dry run and then chezmoi apply on Korolev from the PR branch, accepts zero drift or every named difference, and records post-apply convergence/application checks. Agents never run live engine dry run, apply or elevation. The pre-apply dry run named two intended differences: the npm closure had no lock marker yet and the ReNeo startup command moved to pwsh. Apply at b07f239 reinstalled the closure from the identical lock and changed the ReNeo value. Afterwards the dry run reported all 61 resources desired, a repeated apply did nothing and `chezmoi verify --exclude=scripts` passed. OpenSpec 1.14.0, pyright 1.1.411, TypeScript 5.9.3 and typescript-language-server 5.3.0 resolved natively.

## 4. Shared development hook deployment

- [ ] 4.1 After merge, rerun native development bootstrap in updated main to migrate the exact shared repository-owned Git launcher to pwsh. Until then, mixed-version worktrees use worktree-local hooksPath and shared main retains its PowerShell 5.1 launcher.
