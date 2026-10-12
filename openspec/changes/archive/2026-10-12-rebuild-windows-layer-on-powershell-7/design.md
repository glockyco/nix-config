# Design

## Context

See proposal.md for motivation. The shipped document contains 61 resources: 26 WinGet packages, five official archives, one npm closure, AltSnap, user fonts and 27 settings. Chezmoi already owns app configuration and lifecycle hooks. The native Windows delta is not archived, so this change explicitly targets its resulting contracts rather than the older Nix-rendered main specification.

## Goals / Non-Goals

Goals: one in-process PowerShell 7 convergence engine, reviewable data, fast no-op applies and mocked behavior tests. Preserve roles and supported settings without duplicating chezmoi destinations.

Non-goals: an installer framework, universal version solver, scheduler, retry layer, managed-policy bypass, network enrollment, WSL retirement, TeX Live installation or machine-wide settings in the engine.

## Decisions

### Data and kinds

Ship `windows/workstation.json` with `schemaVersion`, ordered `applications` and `settings` arrays. Each entry has a stable name and `kind`. Applications carry id, roles, scope and a version policy (`present` or `pinned`). A pinned declaration carries version and named consumer. Installation-specific data belongs to that entry, not embedded executable scripts.

Kinds are `winget`, `archive`, `npm`, `font`, `registry`, `language`, `inputMethods`, `appearance`, `animation` and `taskbarVisibility`. AltSnap uses the archive handler with its two owned-file hashes and APPDATA destination. Official ZIP/7z resources use the same handler with LOCALAPPDATA destination, payload/executable/version arguments and reviewed URL/hash. Fonts carry the archive hash and four exact face hashes/registry names. The npm closure keeps npm's own `package.json` and `package-lock.json` in `windows/npm/`, and the data names only that directory. `npm ci` installs it under LOCALAPPDATA Programs/npm and the engine writes the lock's SHA-256 beside it. The closure is desired when that marker matches the repository lock, so the engine never re-verifies packages one by one. Its exact OpenSpec consumer is omp-agent-setup's reusable workflow. Other closure versions are lock-selected delivery, not independent engine version pins.

`workstation.schema.json` uses built-in `Test-Json -Schema`. Reject unknown kinds and fields. Add a small invariant gate for unique names/ids, machine allowlist, managed-app conflicts, HKCU-only writes and prohibited surfaces. No custom JSON Schema implementation or mutation suite.

### One module and thin entrypoint

`windows/Workstation.psm1` owns native invocation, installed snapshot, portable discovery, path convergence and test/set pairs per kind. `windows/workstation.ps1` imports it and selects explicit `-DryRun` or `-Apply`. Dry run reports each resource as desired or drift and exits 0 only when all match. Exit 1 indicates drift. Exit 2 indicates an execution/validation error. Dry run never downloads, extracts, changes PATH, mutates registry, invokes installers or uses temporary output files. Apply tests before setting and retests after a write. Unchanged resources invoke no set operation. Failed native calls stop without retry.

Use one `winget list` snapshot before testing, without a scope filter. After installs or updates only, refresh the snapshot once to verify all changed packages together. A no-op run has one snapshot and an applying run has at most two. Parse full declared package ids and installed version columns in memory. Reject truncated or ambiguous records rather than claim convergence. Avoid `winget export`, which requires an output-file write and violates dry-run safety. Installs use explicit `--id`, `--exact`, `--source winget`, `--scope user` or allowlisted machine scope, agreement flags and `--skip-dependencies`. Scope is an installation constraint, not a WinGet list detection filter. No per-app list/show or catalog queries on a no-op run.

Discover portable executables in the selected WinGet package root, including nested directories, with exactly one match. Do not assume WinGet Links exists. Node's adjacent npm.cmd comes from that root. Refresh process PATH from persisted user/machine values after installations. Native exit codes decide success with PSNativeCommandUseErrorActionPreference disabled within the helper. npm notices on stderr are diagnostic output, not failure.

Present WinGet packages are desired when installed, regardless of available upgrades. Bun's consumer pin and OpenSpec's consumer pin must match. A newer installed pinned version is reported as incompatible but is never downgraded by apply. Archives retain reviewed release/hash selections for missing installations. Existing newer executable versions are accepted. Hash verification precedes extraction, executable checks follow it, and prior install directories remain available for recovery. ImageMagick uses absolute inbox System32/tar.exe and four-component hyphen-aware version comparison. Differing existing font bytes require owner review, never overwrite or delete unrelated fonts.

### Privilege and settings boundaries

Reject an elevated engine session so HKCU cannot target an Administrator profile. Zen, Tailscale and Docker Desktop are the only machine package exceptions and may request installer UAC, never elevate the engine. Docker uses exactly `install --quiet --backend=wsl-2 --no-windows-containers`. No license acceptance flag, service flag or docker-users membership operation.

Keep `apply-kbdneo.ps1` and `apply-zen-policies.ps1` standalone explicit owner-run Administrator tools. Their execution host becomes pwsh at cutover. Native Neo registration is a read-only prerequisite check before input-method changes. Preserve German/Austrian tips, English UI with no English input, QWERTZ first/default and native Neo second. Preserve the existing English placeholder workaround Windows needs during writes. Appearance checks dark flags, transparency and wallpaper rather than requiring an active theme path. Animation uses a single cached native API type. Registry convergence preserves exact types, expands paths only where declared and supports value absence.

Keep taskbar visibility as a typed setting: StuckRects3 byte 8 equals 2. Change only that byte and restart Explorer only after a real change. The taskbar prohibition covers the pinned-application list, not approved visibility. No default associations, CloudStore, pinned-application list or HKLM mutation is allowed.

### Bootstrap, tooling and CI

The only Windows PowerShell 5.1 entrypoint is a minimal fresh-machine `windows/bootstrap.ps1`, documented in README and the operations runbook. It installs pwsh, Git and chezmoi with approved user-scope WinGet commands, resolves their portable roots and hands off to PowerShell 7 without running workstation apply.

Port native development bootstrap/format/hook/tools/ci and lefthook dispatch to pwsh. Retain the shared formatter declaration, locked formatter tooling and same-checkout staged Nix boundary. Install pinned Pester 5 and PSScriptAnalyzer via PSResourceGet under the checkout's Git-local `engine-modules` directory, separate from replaceable formatter tools, or runner temp. Never install into the owner's global module directories.

One Windows job named `check (windows-latest)` runs in runner pwsh, caches reviewed download/module inputs, restores repo-local dependencies, runs shared formatting once, built-in schema validation, PSScriptAnalyzer, parser checks, invariants, Pester mocks and surviving chezmoi/lifecycle fixtures. No WinGet/DSC provision, PowerShell 5.1 matrix, extra pwsh ZIP or aggregate runner remains. Emit per-gate durations and report observed job/step timings. Aim for about two minutes, measured rather than asserted.

### Tests

Pester tests cover one behavior each: one initial snapshot and one conditional grouped post-install refresh, desired no-op, missing install arguments/scope, consumer pin mismatch and no downgrade, Pandoc detection without scope filtering, package-root discovery with empty Links, ambiguity failure, native stderr success/nonzero failure, archive checksum-before-extraction/recovery/7z extraction, npm closure and adjacent npm resolution, font refusal/preservation, PATH idempotence, registry types/absence, language preservation/English placeholder, input ordering/Neo prerequisite, generated Custom.theme acceptance, animation convergence, dry-run no writes/drift/error exit and apply postcondition. Separate invariants cover machine allowlist, Docker arguments, Intune exclusions, prohibited registry surfaces and parsed Administrator-script ownership. Retain proportional rendered-chezmoi/lifecycle and native hook fixtures where they test distinct surviving behaviors, not the removed DSC checker.

## Risks / Trade-offs

- WinGet list output can vary with localization and column width. Fixtures cover headings, spacing, upgrade columns and ambiguous/truncated ids. The integrator checks the actual Korolev snapshot read-only during dry run.
- Broader installed-state detection no longer treats WinGet's ARP scope classification as authoritative. Explicit scope stays mandatory on installation.
- Reviewed archive/npm/font content selects reproducible delivery despite the present policy. Future selected payload updates remain ordinary data changes without automatic downgrade.
- Real language and native API behavior needs owner live acceptance. Mocked tests do not claim it.

## Migration Plan

The PR includes the engine, data, mocked checks, hash-protected chezmoi invocation, pwsh interpreter and full legacy deletion. Remove the WinGet document, vendored DSC schemas, bespoke contract checker, mutation fixtures, installer doubles, Desktop preludes and legacy CI provisioning/legs. Retain distinct user-file/lifecycle, parser and Administrator-boundary coverage under pwsh. Git history is the legacy source rollback. Before merge, the integrator alone runs the dry run on Korolev from the PR branch, accepts zero drift or every named difference, refreshes persisted chezmoi init and runs chezmoi apply followed by convergence and application checks. Source rollback does not restore mutated user state, so retain permission-aware backups. Shared Git launcher migration remains a post-merge development-bootstrap step, with worktree-local hooks before merge. No agent runs live engine dry run or apply.
