# windows-workstation-layer Specification

## Purpose

Define a reviewable Windows workstation configuration layer with explicit ownership, privilege boundaries, application state, and verification requirements.

## Requirements

### Requirement: Rendered Windows configuration artifacts

The repository SHALL maintain declarative JSON application/settings data, its schema, one PowerShell 7 convergence module and narrow standalone Zen-policy, Neo-driver and OpenSSH-server Administrator scripts under `windows/`. The engine SHALL own installations and supported user settings. Chezmoi SHALL exclusively own user/app files. Nix activation SHALL neither write Windows paths nor apply Windows artifacts. No WinGet Configuration document or embedded DSC test/set scripts SHALL remain in the cutover PR.

#### Scenario: Inspect source offline

- **WHEN** the reviewed checkout is inspected without network or a Nix build
- **THEN** all Windows declarations and execution sources are available
- **AND** every destination has exactly one owner

#### Scenario: Render the artifacts

- **WHEN** the native checkout is reviewed
- **THEN** JSON data, its schema, the module and the three narrow Administrator scripts are available without Nix rendering

#### Scenario: Evaluate without network

- **WHEN** source is inspected offline
- **THEN** declarations require no download or mutable Windows state

#### Scenario: Keep the operating-system boundary

- **WHEN** a Nix generation activates
- **THEN** it writes no Windows path and starts no Windows apply

### Requirement: User scope with explicit machine exceptions

The engine SHALL run as the standard interactive account and reject elevated execution. Only Zen, Tailscale and Docker Desktop SHALL declare machine scope and installer elevation. Other installations SHALL explicitly request user scope and SHALL NOT install competing runtime dependencies. The Administrator scripts SHALL retain only Zen Program Files policies, Neo DLL/registration and Korolev OpenSSH server ownership. TeX Live and tailnet enrollment SHALL remain separate owner operations.

#### Scenario: Install approved packages

- **WHEN** a missing package is installed
- **THEN** only an allowlisted machine installer may request Administrator credentials
- **AND** the engine and HKCU writes remain in the standard user's session

#### Scenario: Preserve Docker consent and least privilege

- **WHEN** Docker Desktop is installed
- **THEN** installer arguments are `install --quiet --backend=wsl-2 --no-windows-containers`
- **AND** configuration does not accept the license, enable always-run service or alter docker-users membership

#### Scenario: Reject an unsafe declaration

- **WHEN** data declares an unapproved machine package, HKLM write or centrally managed application
- **THEN** validation and execution fail before changes

#### Scenario: Apply user-scope resources

- **WHEN** the standard user applies the data
- **THEN** all resources except the three allowlisted installers complete without elevation

#### Scenario: Apply the browser exception

- **WHEN** Zen installation requests credentials and the owner separately applies policies
- **THEN** machine writes are limited to Zen installation and its Program Files policies

#### Scenario: Apply the keyboard driver exception

- **WHEN** the owner runs the Neo script as 64-bit Administrator
- **THEN** it writes only declared DLLs and b0000407 registration before an owner restart

#### Scenario: Apply the OpenSSH server exception

- **WHEN** the owner runs the OpenSSH script as Administrator
- **THEN** it writes only the OpenSSH capability, default shell, host-key and authorized-key ACLs, `sshd_config`, its named firewall rule and the sshd service settings
- **AND** sshd stays stopped while another enabled inbound rule could admit TCP 22

#### Scenario: Reject another privileged declaration

- **WHEN** an undeclared privileged installer or machine-setting write is added
- **THEN** validation rejects it before execution

### Requirement: Pinned application set

Each application SHALL declare present or consumer-pinned policy. Bun SHALL be pinned to 1.3.13 for omp-agent-setup's .bun-version and OpenSpec to 1.14.0 for its reusable workflow. Any other version pin SHALL name a concrete consumer. Present applications SHALL install the selected latest WinGet version when missing and SHALL NOT trigger automatic upgrades. Reviewed archive/npm/font integrity selections SHALL retain reproducible missing-install delivery without downgrading existing newer applications. No application SHALL be downgraded automatically.

#### Scenario: Accept an existing present application

- **WHEN** a present application is installed
- **THEN** it is desired without querying the catalog or reinstalling it

#### Scenario: Protect a newer consumer-pinned install

- **WHEN** an installed pinned application is newer than its declared version
- **THEN** dry run reports the incompatibility
- **AND** apply refuses to downgrade it

#### Scenario: Exclude managed applications

- **WHEN** an application id appears in windows/managed-applications.json
- **THEN** repository validation and execution reject the competing declaration

#### Scenario: Install the declared set

- **WHEN** applications are missing
- **THEN** present applications install selected release payloads and consumer-pinned applications install their required versions

#### Scenario: Accept a newer vendor update

- **WHEN** a present application has updated itself
- **THEN** it is desired and no downgrade or reinstall occurs

#### Scenario: Detect an unpinned application

- **WHEN** a declaration lacks a policy or a pinned policy lacks a version and named consumer
- **THEN** schema or invariant validation fails

#### Scenario: Detect a managed-application conflict

- **WHEN** a declared application appears in the managed exclusion audit
- **THEN** validation fails and names its id

### Requirement: Native Ferdium communication client

The hand-maintained Windows application set SHALL declare `Ferdium.Ferdium` as the user-scoped `communication-client` package. The package SHALL run as a native Windows application and SHALL NOT be installed through NixOS, Home Manager, WSLg, or a machine-scoped installer.

#### Scenario: Install Ferdium

- **WHEN** the interactive user applies the Windows configuration without Ferdium installed
- **THEN** WinGet installs the latest available Ferdium version in that user's scope without elevation
- **AND** the user can launch Ferdium as a native Windows application

#### Scenario: Validate the platform boundary

- **WHEN** the repository validates all host configurations
- **THEN** the Windows application set contains exactly one `communication-client` package with identifier `Ferdium.Ferdium`
- **AND** the NixOS and Darwin user package sets do not gain Ferdium from this declaration

### Requirement: Ferdium-owned state and preferences

Ferdium SHALL own its profile, configured services, credentials, sessions, cache, automatic-update preference, and startup preference. The Windows configuration SHALL NOT write those values, authenticate an account, launch Ferdium, add a repository-owned updater, or add a repository-owned startup entry. A fresh Ferdium profile SHALL use the application's default enabled automatic-update preference and disabled startup preference. A later configuration apply SHALL preserve user changes to either preference and all other profile state.

#### Scenario: Launch a fresh installation

- **WHEN** the user launches Ferdium for the first time after installation
- **THEN** Ferdium reports automatic updates as enabled
- **AND** Ferdium reports launch at sign-in as disabled
- **AND** the Windows configuration has not authenticated or configured a service

#### Scenario: Apply over an existing profile

- **WHEN** the user applies the Windows configuration after configuring Ferdium
- **THEN** the existing profile, services, credentials, sessions, cache, and preferences remain in place
- **AND** the apply operation does not launch Ferdium

#### Scenario: Remove the declaration

- **WHEN** a later reviewed configuration removes the Ferdium package declaration
- **THEN** the repository does not delete Ferdium's writable user profile
- **AND** application removal and profile deletion remain explicit user operations

### Requirement: Declared Windows settings

The engine SHALL converge the existing supported registry, keyboard, Explorer, region, snapping, screenshot, dark appearance and animation settings. It SHALL preserve German and Austrian input methods, place en-GB first with no English input method, use en-GB UI override, and place German QWERTZ first/default with native Neo second. Native Neo driver installation and restart SHALL remain an owner prerequisite. Dark appearance SHALL accept generated Custom.theme when flags, transparency and wallpaper match.

#### Scenario: Preserve input and application state

- **WHEN** settings are converged
- **THEN** declared values match without deleting undeclared German/Austrian input methods or application-owned state
- **AND** Neo is not made the default or first keyboard layout

#### Scenario: Accept generated dark appearance

- **WHEN** dark flags, transparency and wallpaper match but Windows selects Custom.theme
- **THEN** the engine reports desired state without rewriting the theme path

#### Scenario: Apply the declared settings

- **WHEN** supported settings are applied
- **THEN** keyboard, Explorer, region, snapping, screenshot, dark appearance and disabled animation/transparency match

#### Scenario: Retain a generated custom theme

- **WHEN** dark appearance matches through Custom.theme
- **THEN** no active theme-file path is rewritten

#### Scenario: Prevent Firefox from starting at sign-in

- **WHEN** the engine converges startup settings
- **THEN** the declared Firefox startup value is absent and its managed installation is untouched

#### Scenario: Separate interface and input languages

- **WHEN** the owner signs in after language convergence
- **THEN** en-GB is the UI override without English input and Austrian/German inputs remain available

#### Scenario: Keep standard Office shortcuts

- **WHEN** Word uses German QWERTZ or native Neo after owner sign-in
- **THEN** QWERTZ remains first/default and standard Ctrl letter shortcuts retain their Windows meaning

#### Scenario: Reject a native Neo default

- **WHEN** data places native Neo first or makes it default
- **THEN** validation fails

#### Scenario: Resist an upstream default change

- **WHEN** an app update changes a chezmoi-owned disabled module setting
- **THEN** chezmoi restores its declared keys without assigning the file to the engine

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

### Requirement: Windows-first Zed control shortcuts

The Windows chezmoi source SHALL keep Zed Vim mode enabled and SHALL declare a user keymap for full editors. In every Vim mode, standard Windows and VS Code `Ctrl` shortcuts SHALL take precedence over Vim's `Ctrl` commands. The standard shortcuts SHALL include copy, cut, paste, select all, undo, redo, save, find, replace, quick open, command palette, new file, open file, recent projects, symbol search, go to line, select next occurrence, dock toggles, and close editor. `Ctrl+K` SHALL remain available as the base keymap's chord prefix. Vim-only single-key `Ctrl` commands that have no selected Windows action SHALL do nothing in a full editor.

The override SHALL NOT change unmodified Vim keys, `Escape`, terminal input, menus, panels, or other non-editor surfaces. The chezmoi apply operation SHALL converge the declared keymap as complete configuration rather than preserve undeclared keymap entries.

#### Scenario: Copy from normal mode

- **WHEN** a full Zed editor is in Vim normal mode and the operator presses `Ctrl+C`
- **THEN** Zed invokes its editor copy action
- **AND** Zed does not invoke a Vim mode or operator action

#### Scenario: Use standard shortcuts across Vim modes

- **WHEN** a full Zed editor is in normal, visual, insert, replace, operator, or waiting mode
- **THEN** each declared standard `Ctrl` shortcut invokes the same Zed action in every mode
- **AND** `Escape` remains the way to cancel an operator or return to normal mode

#### Scenario: Use Vim without its control layer

- **WHEN** the operator uses an unmodified Vim motion, operator, text object, register, or command in a full editor
- **THEN** Zed retains its Vim behavior
- **AND** a Vim-only single-key `Ctrl` command selected for removal does not run

#### Scenario: Use a base keymap chord

- **WHEN** the operator starts a declared `Ctrl+K` chord in a full editor
- **THEN** Zed waits for and runs the base keymap chord
- **AND** it does not start Vim's digraph input

#### Scenario: Use a terminal or non-editor surface

- **WHEN** focus is in Zed's terminal, menu, panel, or another non-editor surface
- **THEN** the surface retains its existing context-specific `Ctrl` behavior

#### Scenario: Converge a changed keymap

- **WHEN** the Windows Zed keymap contains an undeclared binding or differs from the chezmoi declaration
- **THEN** the apply operation restores the complete declared keymap
- **AND** the next chezmoi verification reports the declared keymap in the desired state

### Requirement: Excluded Windows surface

The engine SHALL NOT write taskbar pinned-application lists, default application associations, CloudStore or centrally managed application installation state. Approved taskbar visibility SHALL remain declared as a typed setting with StuckRects3 byte 8 equal to 2. Explorer SHALL restart only when that value actually changes, never on a no-op apply.

#### Scenario: Keep unsupported surfaces user-owned

- **WHEN** the engine runs dry run or apply
- **THEN** no taskbar pinned-application list, default-association or CloudStore mutation is planned or executed

#### Scenario: Inspect the excluded surface

- **WHEN** the layer and runbook are reviewed
- **THEN** exclusions have reasons and no pinned-application list, association or CloudStore writes exist
- **AND** manual Night Light remains sunset to sunrise at 50 percent strength

#### Scenario: Preserve taskbar visibility idempotently

- **WHEN** taskbar auto-hide is enabled and apply runs
- **THEN** only the declared byte becomes 2 and Explorer restarts once
- **AND** an already-desired taskbar triggers neither a registry write nor an Explorer restart

### Requirement: Validation before and after apply

Data SHALL be validated against its schema and privilege/ownership invariants before execution. Dry run SHALL report every declared resource as desired or drift, make no persistent or temporary writes, return zero only for full convergence, return nonzero for drift and distinguish execution errors. Apply SHALL test before setting, mutate only drifted resources, confirm each change and propagate native failures by exit code rather than stderr. Installed WinGet discovery SHALL use one initial batch without scope filtering and, only after installs or updates, one fresh batch to verify all changed packages together. Portable executables SHALL resolve from their selected package root or approved PATH resolution, never an assumed WinGet Links directory.

#### Scenario: Preview a converged workstation

- **WHEN** the integrator runs dry run on a desired workstation
- **THEN** every resource is desired and exit status is zero
- **AND** no installer, download, filesystem, registry or PATH write occurs

#### Scenario: Detect drift without apply

- **WHEN** any resource differs
- **THEN** dry run names the resource and returns nonzero without changing it

#### Scenario: Batch WinGet and preserve per-user MSI detection

- **WHEN** a run checks all WinGet declarations including Pandoc
- **THEN** one initial installed snapshot serves all tests without --scope filtering
- **AND** only actual installations or updates trigger one fresh batch for all changed-package postconditions
- **AND** any needed user installation still explicitly supplies --scope user

#### Scenario: Treat native stderr correctly

- **WHEN** npm writes a notice to stderr and exits zero
- **THEN** the native operation succeeds
- **AND** a nonzero native exit stops apply without automatic retry

#### Scenario: Validate without Windows

- **WHEN** a non-Windows platform reviews source
- **THEN** declarations remain inspectable but native mocked/parser validation is not falsely reported as exercised
- **AND** required Windows CI runs without workstation writes or production credentials

#### Scenario: Preserve stable dark appearance acceptance

- **WHEN** Windows selects Custom.theme with matching declared appearance
- **THEN** dry run accepts it without requiring a fixed theme path

#### Scenario: Reject a dependency on an undeclared resource

- **WHEN** data adds an unsupported dependency field or names an undeclared prerequisite
- **THEN** schema/invariant validation rejects it
- **AND** ordered Node/npm prerequisites remain explicit and validated

#### Scenario: Preview and confirm on the machine

- **WHEN** the integrator tests the engine and each Administrator script before and after approved apply
- **THEN** preview writes nothing and post-apply tests report matching state or named failures

### Requirement: Dedicated browser-relay application

The hand-maintained Windows application set SHALL declare Brave as a self-updating, user-scope Chromium-based browser for native OMP browser relay use. The relay browser SHALL have a distinct application role, SHALL NOT replace Zen as the interactive browser, and SHALL NOT appear in the centrally managed application set. The Windows declaration SHALL configure no startup entry for the relay browser.

#### Scenario: Apply the Windows application declaration

- **WHEN** the interactive user applies the Windows configuration without Brave installed
- **THEN** WinGet installs the latest available Brave version in that user's scope without elevation
- **AND** Zen remains the declared interactive browser

#### Scenario: Detect an invalid relay browser declaration

- **WHEN** Brave is absent, uses a policy other than self-updating, is machine-scoped, is assigned the interactive browser role, or is listed as centrally managed
- **THEN** repository validation fails

#### Scenario: Sign in after a restart

- **WHEN** Windows restarts after the relay browser is installed
- **THEN** the relay browser does not start automatically
- **AND** starting Zen requires no relay browser process

#### Scenario: Remove the relay browser capability

- **WHEN** the relay browser declaration is removed and the Windows configuration is applied
- **THEN** no NixOS generation change is required
- **AND** the operator can remove the browser-owned relay profile and extension independently

### Requirement: Check expectations derive from the declaration

Checks SHALL derive mutable application/version/release/settings facts from JSON and the managed exclusion audit, not duplicate them in checker code. Only stable privilege, role identity and ownership invariants SHALL be literals. The engine data SHALL be the application/settings authority rather than a declaration rendered into a second document.

#### Scenario: Change one pin

- **WHEN** a reviewed version/hash changes in data
- **THEN** checks consume the new declaration without a matching checker edit

#### Scenario: Declare a self-updating application

- **WHEN** Zed, Brave or Ferdium declares present policy
- **THEN** checks accept an existing installation without catalog queries or application-specific version exceptions

#### Scenario: Declared application absent from the document

- **WHEN** a required role has no unique application in JSON
- **THEN** invariants fail and name the role

#### Scenario: Rendered version policy differs from the declaration

- **WHEN** a pinned declaration lacks its version/consumer or a present declaration carries a consumer pin
- **THEN** schema validation fails

#### Scenario: Review file set differs from the declaration

- **WHEN** a declared installation payload or prerequisite source file is missing
- **THEN** validation names the missing source rather than silently skip it

#### Scenario: Reject a different named application

- **WHEN** required Zen, Zed, Brave or Ferdium role identity changes outside the contract
- **THEN** invariants reject that role without copying its mutable version or profile state

### Requirement: Every script parses

The repository SHALL parse all shipped Windows scripts, the module, every Administrator script and rendered chezmoi hooks with the PowerShell 7 parser. The narrow Administrator boundary SHALL remain enforced from parsed references and values. Only the minimal fresh-machine prerequisite bootstrap MAY use Windows PowerShell 5.1.

#### Scenario: Remove the second host

- **WHEN** migrated chezmoi hooks and development tools run
- **THEN** they run in PowerShell 7 without Desktop module-path repair or child Windows PowerShell processes

#### Scenario: A script does not parse

- **WHEN** a shipped or rendered script contains a syntax error
- **THEN** checks fail with its path and parser message

#### Scenario: A script refactor keeps the check green

- **WHEN** a script is restructured without changing its allowed reads/writes
- **THEN** parsed boundary checks remain green without source-substring exceptions

### Requirement: Owner-confirmed engine cutover

The PR SHALL contain the engine cutover, hash-protected chezmoi invocation, persisted pwsh interpreter and complete obsolete DSC source deletion. Git history SHALL retain the legacy source for rollback. Only the integrator SHALL dry run or apply against Korolev. Before merge, the integrator SHALL run the dry run and then chezmoi apply from the PR branch, record zero drift or accept every named difference, and confirm post-apply convergence. Source rollback SHALL NOT be represented as restoration of mutated user state. Agents SHALL report only mocked local verification.

#### Scenario: Review before live acceptance

- **WHEN** the complete cutover PR is ready but live parity is unconfirmed
- **THEN** the PR remains unmerged
- **AND** only mocked local verification is reported
- **AND** the legacy source remains recoverable from Git history rather than an active second implementation

#### Scenario: Complete the approved cutover

- **WHEN** the integrator runs the PR branch dry run and chezmoi apply and accepts parity or every named difference
- **THEN** post-apply convergence and application checks are recorded before merge
- **AND** no separate post-parity source deletion phase is required

### Requirement: Native PowerShell shell tools

The Windows application set SHALL declare Starship from its official release archive, zoxide and eza as WinGet packages, and PSFzf and git-completion as PowerShell Gallery modules. Each SHALL install in the standard user's scope with present policy and its own application role. None SHALL use a machine-scope installer, request elevation or install into the Windows PowerShell 5.1 module path.

#### Scenario: Install the shell tools

- **WHEN** the standard user applies the declarations on a workstation without these tools
- **THEN** a fresh PowerShell 7 session resolves `starship`, `zoxide` and `eza` from PATH
- **AND** PSFzf and git-completion import from the PowerShell 7 current-user module path
- **AND** no step requests Administrator credentials

#### Scenario: Reject a competing declaration

- **WHEN** data installs Starship through a machine-scope installer or assigns a shell-tool role to another application
- **THEN** validation fails before any change and names the application or role

#### Scenario: Keep a newer tool

- **WHEN** an installed shell tool or module is newer than its reviewed release
- **THEN** dry run reports it as desired
- **AND** apply neither reinstalls nor downgrades it

### Requirement: PowerShell Gallery module delivery

A PowerShell Gallery module declaration SHALL name the module, its reviewed release version and the SHA-256 of that release's package. A module SHALL be desired when the PowerShell 7 current-user module path holds it at the reviewed or a newer version. Apply SHALL install a missing module only from the reviewed package after verifying its hash and manifest version. Delivery SHALL NOT change PATH, register or trust a repository, or replace a newer installed version.

#### Scenario: Install a missing module

- **WHEN** apply runs while a declared module is absent
- **THEN** the reviewed package is downloaded and its hash verified before extraction
- **AND** the module manifest in the current-user module path reports the reviewed version
- **AND** a fresh PowerShell 7 session imports the module by name

#### Scenario: Reject a mismatched package

- **WHEN** the downloaded package hash or its manifest version differs from the declaration
- **THEN** apply fails and names the module
- **AND** the current-user module path is unchanged

#### Scenario: Preview a missing module

- **WHEN** dry run runs while a declared module is absent
- **THEN** it reports the module as drift without downloading or writing files

### Requirement: Native checkout and user ownership

Korolev SHALL use a native Windows checkout below the ghq root `~/src` as chezmoi `sourceDir`, selecting host `korolev` and Windows-specific shared facts. Git and SSH files SHALL reuse the shared templates; Zed SHALL preserve app-owned state. User apply SHALL not configure OpenSSH services or copy credentials from another platform; privileged package exceptions SHALL remain explicitly approved.

#### Scenario: Apply from the native checkout

- **WHEN** the standard Windows account initializes chezmoi from its local checkout
- **THEN** `.chezmoiroot` selects `home/` and the recorded `sourceDir` remains that checkout
- **AND** Windows username/home paths do not resolve to the WSL user's paths
- **AND** repeating apply preserves undeclared application state and writes no Administrator-profile file

#### Scenario: Select Git identity

- **WHEN** Git runs in a repository whose remote points at github.com, in a repository below `~/src/github.com/`, or in any other repository
- **THEN** the first two use `11704293+glockyco@users.noreply.github.com` and the others use global `johann.glock@scch.at`
- **AND** a repository-local email overrides either selection
- **AND** Git uses Windows GCM and preserves the Overleaf generic-provider declaration

#### Scenario: Commit from a GitHub clone outside the GitHub tree

- **WHEN** a repository cloned from github.com over HTTPS or SSH lives outside `~/src/github.com/`, such as a scratch directory
- **THEN** its commits use `11704293+glockyco@users.noreply.github.com`
- **AND** a repository outside that tree with a gitlab.scch.at remote keeps `johann.glock@scch.at`

#### Scenario: Apply package configuration after a source change

- **WHEN** the workstation declaration or engine changes and the standard user runs `chezmoi apply`
- **THEN** a content-hashed onchange operation runs the PowerShell 7 workstation engine from the checkout and propagates failure
- **AND** an unchanged apply does not rerun that operation
- **AND** the Administrator scripts remain explicit elevated runs

### Requirement: Native Korolev agent session

Korolev SHALL run standalone upstream OMP in Tern against a local Windows checkout, installed and updated by Tern as the single OMP installation, with the personal plugin installed/upgraded by OMP's plugin manager. Required shell, Git, OpenSpec, research and annotation tools SHALL resolve natively. Credentials and session state SHALL stay Windows-local; saved history SHALL not be represented as a surviving process.

#### Scenario: Complete a real native session

- **WHEN** the owner starts a fresh OMP session in Tern on native Windows
- **THEN** personal policy, skills, namespaced OpenSpec commands, personal commit preview, LSP and Plannotator integration load
- **AND** native PowerShell/Git commands work in paths containing spaces
- **AND** preview creates no commit and annotation returns feedback without changing the source
- **AND** the session records Windows, Tern, OMP, plugin and tool versions plus the reviewed repository revision

#### Scenario: Establish provider access

- **WHEN** provider authentication is needed
- **THEN** the owner completes Windows-local interactive login and a real response verifies each selected provider
- **AND** neither chezmoi nor an installer imports another machine's tokens or authentication database

### Requirement: Native language and document tools

Native Korolev SHALL provide Windows Markdown, Python, TypeScript/Svelte, Typst and LaTeX tools/servers used by its agent/editor, plus the Poppler, QPDF, ImageMagick and Pandoc command-line tools for document work. LaTeX SHALL use TeX Live installed per user from its official installer, including latexmk and biber, with TexLab from its official release. Project SDKs and build settings SHALL remain project-owned. Windows SHALL not satisfy native tools through WSL; nixd and C#/Unity servers SHALL not be installed for this role.

#### Scenario: Diagnose representative work

- **WHEN** OMP opens representative native Markdown, Python, TypeScript and Svelte projects and a Typst document
- **THEN** each declared server initializes, returns applicable diagnostics/navigation, and a native Typst build succeeds
- **AND** no server executable or interpreter resolves through `wsl.exe`, a Linux path or a Nix store

#### Scenario: Build a LaTeX document natively

- **WHEN** the owner builds a representative LaTeX project with latexmk on native Korolev
- **THEN** TeX Live's latexmk and biber produce the PDF and TexLab returns diagnostics/navigation for its sources
- **AND** `pdftotext`, `pdfinfo`, `qpdf`, `magick` and `pandoc` resolve to native Windows executables
- **AND** no build step uses the Mac, WSL or MiKTeX

### Requirement: Stable manually installed terminal

Tern SHALL retain its owner-authenticated manual delivery into a stable per-user PATH location and own its updates. Native PowerShell SHALL be the Korolev terminal workflow; no NixOS secondary session SHALL be required. Repository configuration SHALL not install Windows Terminal or manage Linux profiles. Removing declarations SHALL preserve unrelated terminal profile/session state.

#### Scenario: Launch the primary terminal

- **WHEN** a fresh Windows session resolves and launches Tern
- **THEN** its executable is in the declared stable per-user directory, not a temporary spike folder
- **AND** native PowerShell works without a NixOS distribution
- **AND** clickable links, Unicode/glyphs, paste, resizing and interrupt work without forced environment workarounds

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
