# Design

## Context

See proposal.md for motivation. `home/dot_zshenv.tmpl` already exports Mac environment variables for interactive and non-interactive zsh. The Windows PowerShell profile changes process variables only and returns immediately without PSReadLine. `windows/Workstation.psm1` has persistent environment handling only for user Path, including a Windows environment-change notification. Its settings module already supports typed HKCU registry convergence, but generic registry writes do not send that notification.

The engine reads hand-maintained JSON and validates it before applying resources. Chezmoi invokes it through `home/run_onchange_before_windows-00-workstation.ps1.tmpl`, which hashes its source inputs and verifies the selected checkout. `home/.chezmoidata/portable.toml` already holds cross-platform user preferences. Host-specific identities and paths live in `hosts.toml`.

Programs in Windows Tern panes inherit the Tern daemon's environment, not a sibling PowerShell profile's process variables. The reported observation on 2026-11-23 establishes that a newly started Tern session picks up a persistent user variable. Korolev's manual `setx` value from that date is existing state to adopt, not evidence of repository management.

## Goals / Non-Goals

### Goals

- Keep one address declaration with platform-specific delivery and one Windows convergence owner.
- Make the ordinary engine dry run inspect the same shared value as chezmoi apply.
- Preserve the existing standard-account, validation, idempotence and source-integrity boundaries.

### Non-Goals

- Do not introduce a general secret store, environment synchronization framework or new TOML parser dependency.
- Do not modify PowerShell profile behavior, OMP launchers, plugin caches, Tern configuration, machine environment or package declarations.
- Do not retrofit running processes or terminate Tern or OMP sessions automatically.

## Decisions

### Store the address as a portable research fact

Add `portable.research.unpaywallEmail` in `home/.chezmoidata/portable.toml` with `johann.glock@scch.at`. Both hosts use the same contact, so duplicating it in their host records would misrepresent a personal research setting as a machine fact. Do not derive it from Git email, because Git identity selection and Unpaywall contact policy can change independently. It is a public API contact, not a credential, so encrypted credential sources and account enrollment do not apply. No Nix consumer or typed host-registry field is needed for a fact consumed only by chezmoi and the Windows engine.

### Export through the existing Mac environment template

Read the shared value in the Darwin branch of `home/dot_zshenv.tmpl` and export `UNPAYWALL_EMAIL` with shell-safe quoting. Do not put it in `.zshrc`, because non-interactive commands do not read that file. Do not add launchd environment mutation or an OMP wrapper. The live Tern acceptance gate verifies the actual OMP child process rather than treating template rendering as proof of inheritance.

### Add a typed Windows user-environment setting

Add a `userEnvironment` setting to `windows/workstation.json` and its schema, identifying `UNPAYWALL_EMAIL` and a constrained shared-data reference rather than a second address literal. Resolve that reference before any resource mutation, then use the existing registry state helpers to compare and persist a `String` value under `HKCU:\Environment`. Send the existing environment-change notification only after a changed write and confirm the stored type and value through the normal postcondition path. An existing matching `setx` value is desired state. Preserve all other values and the current Path-specific behavior.

Resolve the shared TOML once with chezmoi's existing `execute-template`, `include` and `fromToml` support, returning JSON for PowerShell to parse. Read the raw source file from the engine's checkout with an explicit source directory, not merged ambient chezmoi data or the globally configured source checkout. The schema and invariants allow only the intended shared-data reference and a nonempty string. No arbitrary template, path or expression comes from the declaration. A missing reader, invalid TOML or invalid value fails before installations or settings writes. This reuses the existing prerequisite instead of adding a PowerShell TOML parser or parsing TOML with regular expressions.

Include the shared TOML file in the engine hook's hashed inputs. Its hash both changes the rendered onchange script when the contact changes and rejects source changes between render and execution. Direct engine dry run resolves the same checkout-local data, so it needs no separately generated JSON or optional command-line email override. Add fixtures for both direct invocation and rendered hook execution.

Alternatives considered:

- A PowerShell profile assignment only updates that PowerShell process and its children, not OMP started independently by Tern. It also skips non-interactive shells.
- A one-time `setx` command leaves no convergence test, postcondition or managed source and does not configure the Mac.
- A plain registry setting can persist the value but cannot consume the shared TOML or send the environment notification with the existing engine unchanged.
- A separate chezmoi environment hook would add another Windows settings writer outside the engine and hide drift from its dry run.
- Rendering a second complete workstation JSON would conflict with the engine's declaration authority. A literal address in its current JSON would duplicate the shared contact.
- A general environment mapping, PowerShell TOML dependency or new launcher layer adds machinery beyond this single shared research setting.

### Keep capability ownership explicit

`user-configuration` owns the cross-platform environment and consumer contract. `windows-workstation-layer` owns persistent user settings, drift reporting and source resolution. Its declaration-authority requirement gains a narrow shared-TOML value-source exception. No new capability or OMP-owned runtime setting is needed.

## Risks / Trade-offs

- Existing Windows processes can retain a stale environment after a registry update. Start a fresh Tern session after applying. If its daemon remains stale, preserve current work and restart Tern normally or sign out and back in before the consumer check. A notification is not proof that a running process refreshed.
- Mac shell startup alone does not prove how Tern starts OMP. The fresh-session acceptance check must print the value from an OMP child command without an inline address assignment. Do not accept a shell-only check as equivalent.
- Direct engine execution now needs the already-required chezmoi executable for this setting. Resolve and validate the source before any mutation and cover missing-reader failure in mocked tests.
- The contact is stored in public source and inherited by child processes. This is intentional for a non-secret API contact. Do not place tokens or passwords in this mechanism.

## Migration Plan

Implement and test the shared declaration, Mac export, Windows resource and hashed hook together. Review diffs for no unrelated removal. Run the repository's platform checks before live acceptance.

On Korolev, run the engine dry run from the reviewed PR branch as the standard account, then chezmoi apply, post-apply dry run, verification and a repeated apply. The matching manually set value needs no deletion or recreation. On the Mac, follow the existing system-switch-before-user-apply procedure and keep the previous generation until checks pass. Verify an OMP child command in a fresh Tern session on each host.

A source rollback restores prior managed user files but does not remove a Windows environment value that the older source never declared. If this new value must be undone, explicitly restore its recorded pre-apply state as the standard account, changing only `UNPAYWALL_EMAIL`, then refresh Tern normally. Do not delete unrelated values or claim that a Nix rollback restores user state.
