# Spec Delta

## MODIFIED Requirements

### Requirement: User scope with explicit machine exceptions

User resources SHALL run as the standard interactive account. Zen, Tailscale for Windows and Docker Desktop SHALL be the only machine-scope package exceptions. Docker Desktop installation SHALL require prior owner/employer licensing confirmation and owner-assisted UAC. OpenSSH Server SHALL remain a separate explicit Administrator capability/service operation, not a user apply resource. The two Administrator scripts SHALL retain only Zen Program Files policy and Neo DLL/registration ownership; they SHALL reject unelevated writes and Administrator-profile paths.

#### Scenario: Apply user-scope resources

- **WHEN** the interactive user applies the document with standard user rights
- **THEN** every resource except the Zen, Tailscale and Docker Desktop packages completes without elevation
- **AND** every other installed application and written file belongs to that user's profile

#### Scenario: Apply the browser exception

- **WHEN** the Zen installer requests the administrator credential and the operator later applies the policy script from an Administrator PowerShell session
- **THEN** both operations write only to the machine-wide Zen installation under Program Files

#### Scenario: Apply the keyboard driver exception

- **WHEN** the operator applies the native Neo script from a 64-bit Administrator PowerShell session
- **THEN** it writes only the checksum-pinned DLLs and `b0000407` machine registration
- **AND** the operator restarts Windows before the document registers input tip `0407:b0000407`

#### Scenario: Reject another privileged declaration

- **WHEN** the document declares an unapproved machine-scope package, elevated resource, machine-scope registry value, or Windows feature
- **OR** either Administrator script refers to an interactive-user profile path or a machine path outside its declared ownership
- **THEN** the repository validation fails

#### Scenario: Apply the network and SSH exceptions

- **WHEN** the owner approves Tailscale installation and the separately documented OpenSSH Server operation
- **THEN** the installer and capability operation use explicitly owner-assisted Administrator credentials
- **AND** chezmoi user-file application remains in the standard account
- **AND** neither existing Administrator script gains service, firewall, or user-profile ownership

#### Scenario: Apply the container runtime exception

- **WHEN** the owner/employer has confirmed Docker Desktop licensing and the owner authorizes its installation
- **THEN** the `Docker.DockerDesktop` installer runs in machine scope with owner-typed UAC credentials
- **AND** user configuration remains in the standard account and neither existing Administrator script gains Docker ownership
- **AND** native Docker CLI and Compose pass an owner-authorized smoke check before container-dependent projects migrate

### Requirement: Pinned application set

Every managed application SHALL carry one explicit version policy. Exact packages SHALL declare a reviewed version; self-updating packages SHALL omit it and require latest available without downgrading newer installed versions. Zed, Zen, Brave, Ferdium, Git, Docker Desktop and Tern SHALL be self-updating; other declared packages SHALL be exact. The set SHALL cover native workstation roles, with Tern installed manually. No Intune-managed installation SHALL have a competing declaration; reviewed update-only packages SHALL not be treated as initial installation ownership.

#### Scenario: Install the declared set

- **WHEN** the operator applies the document on a machine without the declared applications
- **THEN** each exact-pinned application installs at its declared version
- **AND** each document-managed self-updating application installs at the latest version available from WinGet
- **AND** each required role has exactly one declared application or explicit Tern manual-install boundary

#### Scenario: Accept a newer vendor update

- **WHEN** Zed, Zen, Brave, Ferdium, Git or Docker Desktop has a vendor-channel or applicable Intune-update version newer than the latest version available from WinGet
- **THEN** the document reports that application in the desired state
- **AND** an apply operation does not downgrade or reinstall it

#### Scenario: Detect an unpinned application

- **WHEN** an application declares no version policy, more than one version policy, a version under the self-updating policy, or no version under the exact policy
- **THEN** repository validation fails

#### Scenario: Detect a managed-application conflict

- **WHEN** a declared application appears in the recorded set of centrally managed applications
- **THEN** repository validation fails

#### Scenario: Distinguish per-user Git from centrally managed updates

- **WHEN** the reviewed Intune evidence shows its Git update package detects only HKLM installations
- **THEN** the layer declares `Git.Git` for the per-user installation and removes that identifier from the conflicting-app list
- **AND** packages with actual centrally managed installation ownership remain excluded

#### Scenario: Distinguish Docker installation from centrally managed updates

- **WHEN** the owner-confirmed 2026-10-11 Intune log records `Update für Docker Desktop 4.47.0` as update-only delivery
- **THEN** the layer removes `Docker.DockerDesktop` from `windows/managed-applications.json` and declares it as a machine-scope self-updating package without a version pin
- **AND** the dated audit records repository-owned initial installation and Intune-owned updates without changing employer policy
- **AND** owner/employer licensing confirmation remains a prerequisite to installation

### Requirement: Application configuration files

Chezmoi SHALL own Windows app files, enforcing stable content and converging only declared keys in app-rewritten files. Zed/Zen SHALL retain pinned Catppuccin themes. Zed SHALL open native checkouts without Linux transport or an OMP agent server; Fork SHALL use per-user native Git. Nix editing/evaluation/build workflows SHALL use Mac/CI, not secondary WSL. AltSnap, PowerToys and Neo SHALL retain their accepted ownership/ordinary/elevated/UAC boundaries.

#### Scenario: Preserve remembered Zed WSL projects

- **WHEN** existing app-owned recent-project state contains historical WSL entries
- **THEN** chezmoi preserves undeclared UI state without declaring a working Linux transport
- **AND** the owner selects native replacement checkouts; remembered paths are not evidence of supported WSL work

#### Scenario: Enforce a stable configuration file

- **WHEN** an enforced-class file differs from its declaration
- **THEN** apply restores its declared content

#### Scenario: Apply the application themes

- **WHEN** Windows chezmoi source is applied
- **THEN** Zed and Zen select Catppuccin Mocha with Mauve accents
- **AND** managed themes match their pinned source

#### Scenario: Open native editor work

- **WHEN** a local Windows checkout opens in Zed
- **THEN** supported language tools start as native Windows processes
- **AND** no Linux transport, nixd selection or OMP agent server is configured
- **AND** Nix workflows use the Mac and applicable CI

#### Scenario: Run Fork Git operations natively

- **WHEN** Fork operates below the Windows ghq root
- **THEN** it uses the declared per-user Git executable without wslgit
- **AND** it preserves unrelated app-owned settings

#### Scenario: Start the Nix language server

- **WHEN** Nix language-server work is requested from native Windows Zed
- **THEN** managed settings start no nixd and redirect nothing through a Linux environment
- **AND** guidance identifies the supported Mac Nix workflow

#### Scenario: Run Fork Git operations in WSL

- **WHEN** the owner selects an obsolete NixOS UNC repository path after retirement
- **THEN** no managed Linux Git bridge or fallback exists
- **AND** the owner uses the migrated native checkout rather than a secondary environment

#### Scenario: Snap a modifier-dragged window

- **WHEN** the operator modifier-drags a window to an edge or corner
- **THEN** AltSnap snaps to the declared 50/50 region
- **AND** no PowerToys movement module handles the same gesture

#### Scenario: Use Neo in ordinary and elevated surfaces

- **WHEN** the operator signs in and accepts ReNeo's RunAs prompt
- **THEN** ReNeo supplies every Neo layer in ordinary/elevated apps while German QWERTZ is active
- **AND** UAC accepts German QWERTZ because secure desktop rejects process injection

#### Scenario: Select native Neo

- **WHEN** the operator selects native Neo with Win+Space and ReNeo detects the layout
- **THEN** native Neo base layout works in ordinary/elevated apps and UAC
- **AND** ReNeo supplies higher layers in ordinary/elevated apps without replacing the native layout
- **AND** UAC remains limited to the native base layout

#### Scenario: Preserve application-owned state

- **WHEN** a converged app has written its own profile/UI state
- **THEN** apply sets declared values and preserves the app's own values

### Requirement: Stable manually installed terminal

Tern SHALL retain its owner-authenticated manual delivery into a stable per-user PATH location and own its updates. Native PowerShell SHALL be the Korolev terminal workflow; no NixOS secondary session SHALL be required. Repository configuration SHALL not install Windows Terminal or manage Linux profiles. Removing declarations SHALL preserve unrelated terminal profile/session state.

#### Scenario: Launch the primary terminal

- **WHEN** a fresh Windows session resolves and launches Tern
- **THEN** its executable is in the declared stable per-user directory, not a temporary spike folder
- **AND** native PowerShell works without a NixOS distribution
- **AND** clickable links, Unicode/glyphs, paste, resizing and interrupt work without forced environment workarounds

## ADDED Requirements

### Requirement: Windows-only Korolev lifecycle

Korolev SHALL run all owner projects from stable native Windows checkouts as the standard scch\\jglock user. Personal repositories SHALL work on both Korolev and macbook-pro; SCCH work repositories SHALL require Korolev only. Mac Nix/chezmoi SHALL remain supported. Native Windows services/tools SHALL not use the retired NixOS distribution; Docker Desktop's engine-owned distributions SHALL remain outside retirement ownership.

#### Scenario: Work after distribution retirement

- **WHEN** the backed-up NixOS distribution has been unregistered
- **THEN** every migrated project still passes its native Windows acceptance
- **AND** personal projects retain Mac acceptance without requiring SCCH repositories to support the Mac
- **AND** Docker Desktop and native Tailscale/OpenSSH remain usable

### Requirement: Owner-assisted project preservation

The Korolev runbook SHALL require per-project session completion and owner reconciliation/publication of pending work before HTTPS native clones and acceptance. Nested repositories and untracked data SHALL be inventoried and preserved. Project-owned toolchain changes SHALL stay in their own repositories. No reset, credential copy or transcript conversion SHALL be implied by migration.

#### Scenario: Reconcile pending WSL work

- **WHEN** a project is migrated from the source checkout
- **THEN** the owner decides changed/untracked/ahead content and explicitly authorizes any commit/push
- **AND** the native ghq-layout checkout is cloned or reconciled without overwriting pending native work

#### Scenario: Migrate the complete project inventory

- **WHEN** retirement acceptance is reviewed
- **THEN** records cover glockyco's phd-thesis including nested clones, Teralizer-Paper with correspondence, test-generalization, omp-agent-setup and nix-config
- **AND** records cover SCCH saner2027-paper with its Overleaf paper repository, saner2027-overleaf, andritz/anita, andritz/aqua and internal-tools/not-so-personalwolke
- **AND** reference can1357/oh-my-pi\* and backnotprop/plannotator clones are not migration prerequisites

#### Scenario: Preserve ephemeral content

- **WHEN** content outside the source root, including aged /tmp data, is encountered before retirement
- **THEN** the owner makes an explicit preservation decision before export
- **AND** temporary-file aging is not assumed to preserve content until a later backup

#### Scenario: Complete source sessions

- **WHEN** the seven running source OMP sessions reach migration completion
- **THEN** they finish in WSL and their transcripts stay in the retained private backup
- **AND** no session/authentication database is converted or imported into Windows

### Requirement: Private booking skill marketplace

The owner-approved book-project-hours skill SHALL move to a new private glockyco GitHub repository publishing an OMP plugin marketplace, not into SCCH's personalwolke repository. Its complete SKILL.md and evidence.py SHALL remain together. Repository creation/publication and installed plugin identity SHALL require owner review; Korolev SHALL install it in user scope through OMP's plugin manager.

#### Scenario: Preserve and publish the booking skill

- **WHEN** the owner reviews the untracked skill and authorizes its private publication
- **THEN** the approved glockyco marketplace contains both skill files and real marketplace/plugin metadata
- **AND** no pending not-so-personalwolke data is discarded or committed there merely to move the skill

#### Scenario: Install in a native session

- **WHEN** Korolev adds the approved marketplace and installs its booking plugin with --scope user
- **THEN** native OMP discovers book-project-hours and its evidence helper
- **AND** a harmless skill verification books no actual hours without separate authorization

### Requirement: Retained export before destructive retirement

Only after all project acceptance and source-session/preservation gates pass SHALL the owner coordinate a private retained wsl --export NixOS backup and explicitly authorize wsl --unregister NixOS. The runbook SHALL record export integrity/readability and owner-assisted recovery. No Docker Desktop distribution, Windows WSL feature or unrelated user state SHALL be removed.

#### Scenario: Export before unregister

- **WHEN** the owner approves final retirement after workloads are quiescent
- **THEN** the private export succeeds and its location/integrity/readability are recorded before unregister runs
- **AND** NixOS is then absent while engine-owned distributions remain untouched

#### Scenario: Acceptance or export fails

- **WHEN** any project, preservation, session or backup gate is incomplete or fails
- **THEN** unregister does not run
- **AND** retained WSL data remains available while the native failure is repaired

#### Scenario: Recover after unregister

- **WHEN** recovery is explicitly authorized after retirement
- **THEN** the runbook uses the retained private export through an owner-assisted import with reviewed names/paths
- **AND** it claims no Windows credential/tool rollback or conversion of running sessions
