# Tasks

## 1. Declarative inventory and engine

- [x] 1.1 Add workstation.json and its Test-Json schema, preserving all 34 application resources and 27 settings including typed taskbar visibility. Name Bun/OpenSpec consumers and reuse reviewed archives/npm integrity locks.
- [x] 1.2 Implement one PowerShell 7 module and explicit dry-run/apply entrypoint with batched WinGet list, exit-code native handling, desired/drift/error output, post-write checks and no downgrade.
- [x] 1.3 Implement WinGet user/machine installation, exact portable-root resolution, Node-adjacent npm, user PATH convergence and Docker's reviewed override.
- [x] 1.4 Implement checksum-verified official ZIP/7z/AltSnap delivery with retained prior directories, npm ci closure and non-destructive user-font installation.
- [x] 1.5 Implement typed/absent HKCU registry values, preserved language/input ordering, Neo prerequisite, stable dark appearance, animation and taskbar visibility with Explorer restart only after actual changes. Keep Administrator tools and manual TeX Live separate.

## 2. Mocked verification and parallel CI

- [x] 2.1 Add pinned repo-local PSResourceGet Pester 5/PSScriptAnalyzer setup and analyzer settings. Add and document the minimal PowerShell 5.1 pwsh/Git/chezmoi prerequisite bootstrap without live apply.
- [x] 2.2 Add behavior-level Pester mocks for the snapshot, idempotence, dry-run exits/no writes, native stderr/failure, scope/Pandoc, no downgrade, package roots, archive/npm/font safety, PATH and setting convergence.
- [x] 2.3 Add schema/parser and privilege invariants for Intune exclusions, machine allowlist, HKCU/prohibited surfaces, Docker arguments and narrow Administrator scripts. Retain distinct surviving chezmoi/lifecycle/hook coverage.
- [x] 2.4 Coordinate workflow changes with FastCI, rebase after its merged PR and add a pwsh-only engine CI job alongside the untouched legacy document/tests. Run local PowerShell 7 verification against mocks only.
- [x] 2.5 Port Windows dev bootstrap/format/hook/tools/ci and native-windows lefthook dispatch to pwsh in their own pre-parity commit without changing staged Nix validation.
- [ ] 2.6 Open a PR with exact Korolev dry-run command, observed local results and CI job/step timings. Obtain integrator-confirmed live parity or explicit acceptance of named differences. Do not run live dry run or apply as an agent.
- [ ] 2.7 After merging the tooling commit, rerun the native development bootstrap to migrate the shared repository-owned Git launcher to pwsh. Until then, mixed-version worktrees use worktree-local hooksPath and the shared main checkout retains the PowerShell 5.1 launcher.

## 3. Owner-approved cutover

- [ ] 3.1 After parity confirmation only, prepare a separate final commit switching hash-protected chezmoi invocation and persisted interpreter to pwsh.
- [ ] 3.2 Remove the old document, vendored DSC schemas, bespoke checker and checker-only mutation/installer fixtures, obsolete Desktop prelude and WinGet/DSC CI provisioners. Consolidate required Windows CI into one pwsh job with shared formatting once.
- [ ] 3.3 Update the operations runbook and affected callers/tests to the engine commands, local dependency setup, intentional exclusions and recovery policy. Run complete mocked PowerShell 7/static/format verification and strict OpenSpec validation, publish the separate cutover commit for review and report final CI timings.
