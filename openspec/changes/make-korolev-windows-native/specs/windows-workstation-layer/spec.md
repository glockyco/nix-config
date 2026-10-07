## MODIFIED Requirements

### Requirement: Rendered Windows configuration artifacts

The repository SHALL maintain the Windows document and two narrow Administrator scripts as source under `windows/`, independent of Nix rendering. WinGet Configuration SHALL own Windows apps/settings; chezmoi SHALL own user files from `home/`. No file SHALL have two owners. Nix activation SHALL neither write Windows paths nor apply Windows artifacts.

#### Scenario: Render the artifacts

- **WHEN** the reviewed native Windows checkout is inspected
- **THEN** it contains one hand-maintained WinGet Configuration document, one Zen policy script, and one native Neo driver script
- **AND** reading the declarations requires no mutable Windows state

#### Scenario: Evaluate without network

- **WHEN** the source artifacts are reviewed on a machine with no network
- **THEN** the document and scripts are available without a Nix build
- **AND** pinned theme files have one chezmoi owner and are not fetched merely to inspect the Windows source

#### Scenario: Keep the operating-system boundary

- **WHEN** either host activates a Nix generation
- **THEN** activation writes no file under the Windows user profile
- **AND** activation does not start the Windows apply operation

### Requirement: User scope with explicit machine exceptions

User resources SHALL run as the standard interactive account. Zen and Tailscale for Windows SHALL be the only machine-scope package exceptions. OpenSSH Server SHALL be a separate explicit Administrator capability/service operation, not a user apply resource. The two Administrator scripts SHALL retain only Zen Program Files policy and Neo DLL/registration ownership; they SHALL reject unelevated writes and Administrator-profile paths.

#### Scenario: Apply user-scope resources

- **WHEN** the interactive user applies the document with standard user rights
- **THEN** every resource except the Zen and Tailscale packages completes without elevation
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

### Requirement: Pinned application set

Every managed application SHALL carry one explicit version policy. Exact packages SHALL declare a reviewed version; self-updating packages SHALL omit it and require latest available without downgrading newer installed versions. Zed, Zen, Brave, Ferdium, Git and Tern SHALL be self-updating; other declared packages SHALL be exact. The set SHALL cover native workstation roles, with Tern installed manually. No Intune-managed installation SHALL have a competing declaration.

#### Scenario: Install the declared set

- **WHEN** the operator applies the document on a machine without the declared applications
- **THEN** each exact-pinned application installs at its declared version
- **AND** each document-managed self-updating application installs at the latest version available from WinGet
- **AND** each required role has exactly one declared application or explicit Tern manual-install boundary

#### Scenario: Accept a newer vendor update

- **WHEN** Zed, Zen, Brave, Ferdium, or Git has a vendor-channel version newer than the latest version available from WinGet
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
- **AND** Docker Desktop and every other recorded centrally managed package remain excluded

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

### Requirement: Application configuration files

Chezmoi SHALL own Windows application files, enforcing stable content and converging only declared keys in app-rewritten files. Zed and Zen SHALL retain pinned Catppuccin Mocha/Mauve themes. Zed SHALL open native checkouts without WSL transport or an OMP agent server; Fork SHALL use native per-user Git. AltSnap SHALL own modifier movement/snapping without overlapping PowerToys modules. ReNeo and native Neo SHALL retain their declared ordinary/elevated/UAC boundaries.

#### Scenario: Enforce a stable configuration file

- **WHEN** a file in the enforced class differs from the declaration
- **THEN** the apply operation restores the declared content

#### Scenario: Apply the application themes

- **WHEN** the operator applies the Windows chezmoi source
- **THEN** Zed and Zen select Catppuccin Mocha with Mauve accents
- **AND** each managed theme matches its pinned upstream source

#### Scenario: Open native editor work

- **WHEN** the operator opens a local Windows checkout in Zed
- **THEN** supported language tools start as Windows processes
- **AND** no WSL transport, nixd selection, or OMP agent-server entry is configured
- **AND** Nix work remains in the secondary WSL environment

#### Scenario: Run Fork Git operations natively

- **WHEN** Fork operates on a repository below the Windows `~/src` root
- **THEN** it uses the declared per-user Git for Windows executable without wslgit
- **AND** Fork preserves its other application-owned settings

#### Scenario: Start the Nix language server

- **WHEN** the operator requests Nix language-server work from a native Windows Zed checkout
- **THEN** the managed Windows settings do not start nixd or redirect the editor through WSL
- **AND** Nix editing/build workflows use the secondary Nix environment directly

#### Scenario: Run Fork Git operations in WSL

- **WHEN** the operator selects a repository under the secondary WSL filesystem
- **THEN** the managed native Fork configuration supplies no wslgit bridge or Linux Git transport
- **AND** the operator uses the secondary environment's own Git workflow or a separate native checkout

#### Scenario: Snap a modifier-dragged window

- **WHEN** the operator modifier-drags a window to a screen edge or corner
- **THEN** AltSnap moves and snaps the window to the configured 50/50 region
- **AND** no PowerToys movement module handles the same gesture

#### Scenario: Use Neo in ordinary and elevated surfaces

- **WHEN** the operator signs in and accepts the ReNeo `RunAs` prompt
- **THEN** ReNeo supplies every Neo layer in ordinary and elevated applications while German QWERTZ is active
- **AND** UAC prompts accept German QWERTZ input because the secure desktop rejects process injection

#### Scenario: Select native Neo

- **WHEN** the operator selects native Neo with `Win+Space` and ReNeo detects the changed layout
- **THEN** the native Neo base layout works in ordinary applications, elevated applications, and UAC
- **AND** ReNeo supplies higher Neo layers in ordinary and elevated applications without replacing the native layout
- **AND** UAC remains limited to the native base layout because its secure desktop rejects process injection

#### Scenario: Preserve application-owned state

- **WHEN** an application in the converged class has written its own state, such as a generated profile identifier or interface state
- **THEN** the apply operation sets the declared values
- **AND** the apply operation preserves the application's own values

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

### Requirement: Validation before and after apply

Windows-native repository gates SHALL validate the shipped document against its vendored official DSC v3 configuration-document JSON Schema and discovered resource-type allowlist, parse it with read-only `winget configure show`, and test ownership, explicit application selectors, dependencies, machine exceptions and script ASTs without applying resources. Schema sources SHALL retain reviewed release URLs and SHA-256 values. Tests SHALL not read live enrollment or profile state. Before first live apply the operator SHALL preview drift; after applying in the proper account context the operator SHALL confirm all owned state.

#### Scenario: Validate without applying Windows state

- **WHEN** the Windows-native repository checks run in CI or the native development environment
- **THEN** they validate the shipped document against the pinned official schema and resource-type allowlist, every script against the PowerShell parser, the narrow script boundary, each application's version policy and selector, and the absence of a centrally managed application
- **AND** read-only WinGet show exits zero without applying a resource or requiring provider login/device enrollment; missing native parser/schema dependencies fail rather than skip

#### Scenario: Validate without Windows

- **WHEN** a Nix-only environment inspects the Windows source or requests native WinGet parsing
- **THEN** source review remains possible but native validation is not reported as exercised there
- **AND** required Windows CI performs the native gate; a missing Windows runtime/tool does not silently pass

#### Scenario: Preserve stable dark appearance acceptance

- **WHEN** Windows records the declared dark modes, transparency, and wallpaper in `Custom.theme`
- **THEN** the live test reports the dark-appearance resource in the desired state
- **AND** the repository check requires no active theme-file path

#### Scenario: Reject a dependency on an undeclared resource

- **WHEN** a resource in the hand-maintained document depends on a name that no resource in the document declares
- **THEN** the repository check fails and names both resources

#### Scenario: Preview and confirm on the machine

- **WHEN** the operator tests the document and both Administrator scripts on the Windows work machine
- **THEN** each test reports drift without applying it
- **AND** later test operations report that the applied state matches all three artifacts

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

Windows checks SHALL read app policy, selectors, scope, roles, managed exclusions and owned files from the native source declarations. They SHALL not duplicate mutable release pins, palettes or checksum values. Fixed literals SHALL express only invariant schema, identity, dependency, ownership and privilege rules. User-file checks SHALL consume the chezmoi-rendered Windows fixtures, not obsolete Nix review output.

#### Scenario: Change one pin

- **WHEN** a maintainer changes the version or checksum of one exact-pinned application in the declaration in the native source
- **THEN** the repository check passes with no edit to the check
- **AND** the hand-maintained document carries the new pin

#### Scenario: Declare a self-updating application

- **WHEN** the declaration selects the self-updating policy without a version for Zed, Zen, Brave, Ferdium, or Git
- **THEN** the repository check expects catalog-latest test/install semantics with no exact selector (the native DSC package shape uses `useLatest: true`; scope-sensitive scripts enforce the equivalent query/install behavior)
- **AND** the check carries no application-specific exception

#### Scenario: Declared application absent from the document

- **WHEN** the declaration lists an application that the hand-maintained document does not carry as exactly one resource with the same identifier, version policy, policy-specific selector, scope, and roles
- **THEN** the repository check fails and names the application

#### Scenario: Rendered version policy differs from the declaration

- **WHEN** an exact resource carries a mismatched version or permits the latest version
- **OR** a self-updating resource carries a version or does not require the latest version
- **THEN** the repository check fails and names the resource

#### Scenario: Review file set differs from the declaration

- **WHEN** the source-owned file set carries a file that the declaration does not name, or omits one that it names
- **THEN** the repository check fails and names the file

#### Scenario: Reject a different named application

- **WHEN** the declaration replaces the required Zen, Zed, Brave, Ferdium, or Git identity or assigns a policy outside the accepted contract
- **THEN** the repository check fails and names the role
- **AND** the check does not copy a mutable release version or the application's profile data

### Requirement: Every script parses

The repository check SHALL parse every script that the Windows layer ships: each test and set script inside the document, both Administrator scripts, the ReNeo launcher, native check/bootstrap programs, and rendered chezmoi PowerShell scripts. The check SHALL use the PowerShell parser for that purpose and SHALL NOT match script source against substrings. The check SHALL assert the Administrator-script boundary on the parsed variable references and string values.

#### Scenario: A script does not parse

- **WHEN** a shipped or rendered script contains a syntax error
- **THEN** the repository check fails and names the script and the parser message

#### Scenario: A script refactor keeps the check green

- **WHEN** a maintainer restructures a script without a change to the values it reads or writes
- **THEN** the repository check passes with no edit to the check

## REMOVED Requirements

### Requirement: Zed WSL LaTeX builds

**Reason**: Windows is the native primary workstation; Windows Zed no longer transports LaTeX projects or TexLab through WSL.
**Migration**: Compile LaTeX and run TexLab in the Mac's existing full TeX toolchain, keeping project build commands and root markers in each project. Native Windows document work uses Typst/tinymist; any retained WSL TeX packages are secondary tools, not a Windows editor dependency.

### Requirement: Checker errors and self-tests have separate paths

**Reason**: The Nix-built Python Windows checker and its import/console interface are removed.
**Migration**: Native Windows checks report named failing resources/scripts and nonzero exit statuses; controlled negative fixtures replace the checker's package-build self-tests. No obsolete Python CLI shim remains.

## ADDED Requirements

### Requirement: Native checkout and user ownership

Korolev SHALL use a native Windows checkout below the ghq root `~/src` as chezmoi `sourceDir`, selecting host `korolev` and Windows-specific shared facts. Git and SSH files SHALL reuse the shared templates; Zed SHALL preserve app-owned state. User apply SHALL not configure OpenSSH services or copy credentials from another platform; privileged package exceptions SHALL remain explicitly approved.

#### Scenario: Apply from the native checkout

- **WHEN** the standard Windows account initializes chezmoi from its local checkout
- **THEN** `.chezmoiroot` selects `home/` and the recorded `sourceDir` remains that checkout
- **AND** Windows username/home paths do not resolve to the WSL user's paths
- **AND** repeating apply preserves undeclared application state and writes no Administrator-profile file

#### Scenario: Select Git identity

- **WHEN** Git runs below `~/src/github.com/` or below a work/outside directory
- **THEN** the GitHub tree uses `11704293+glockyco@users.noreply.github.com` and other locations use global `johann.glock@scch.at`
- **AND** a repository-local email overrides either selection
- **AND** Git uses Windows GCM and preserves the Overleaf generic-provider declaration

#### Scenario: Apply package configuration after a source change

- **WHEN** the Windows document content changes and the standard user runs `chezmoi apply`
- **THEN** a content-hashed onchange operation invokes `winget configure` on the checkout's document and propagates failure
- **AND** an unchanged apply does not rerun that operation
- **AND** both Administrator scripts remain explicit elevated runs

### Requirement: Native Korolev agent session

Korolev SHALL run standalone upstream OMP in Tern against a local Windows checkout, updated through `omp update`, with the personal plugin installed/upgraded by OMP's plugin manager. Required shell, Git, OpenSpec, research and annotation tools SHALL resolve natively. Credentials and session state SHALL stay Windows-local; saved history SHALL not be represented as a surviving process.

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

Native Korolev SHALL provide Windows Markdown, Python, TypeScript/Svelte and Typst tools/servers used by its agent/editor. Project SDKs and build settings SHALL remain project-owned. Windows SHALL not satisfy native tools through WSL; nixd and C#/Unity servers SHALL not be installed for this role. LaTeX compilation and TexLab SHALL use the Mac, not a Windows-to-WSL editor transport.

#### Scenario: Diagnose representative work

- **WHEN** OMP opens representative native Markdown, Python, TypeScript and Svelte projects and a Typst document
- **THEN** each declared server initializes, returns applicable diagnostics/navigation, and a native Typst build succeeds
- **AND** no server executable or interpreter resolves through `wsl.exe`, a Linux path or a Nix store

### Requirement: Stable manually installed terminal

Tern SHALL be installed from the owner's signed-in closed-beta build service into a stable per-user location on PATH and own its updates. Repository configuration SHALL no longer install Windows Terminal or manage its WSL profile. Removing declarations SHALL preserve unrelated terminal profile/session state.

#### Scenario: Launch the primary terminal

- **WHEN** a fresh Windows session resolves and launches Tern
- **THEN** its executable is under the declared stable per-user directory, not a temporary spike folder
- **AND** native PowerShell is usable and WSL is an explicitly selected secondary session
- **AND** clickable links, Unicode/glyphs, paste, resizing and terminal interrupt work without forced environment workarounds
