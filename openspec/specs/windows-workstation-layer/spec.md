# windows-workstation-layer Specification

## Purpose

Define a reviewable Windows workstation configuration layer with explicit ownership, privilege boundaries, application state, and verification requirements.

## Requirements

### Requirement: Rendered Windows configuration artifacts

The repository SHALL render one Windows configuration document, one Administrator Zen policy script, and one Administrator native Neo driver script from the same Nix expressions. Together they SHALL be the single source for the Windows application set, the declared Windows settings, and the declared application configuration files. Each application SHALL have one declaration that carries its identifier, version policy, policy-specific selector, scope, source, and release data, and every resource that installs or configures that application SHALL derive its metadata from that declaration. Evaluation of the output SHALL read no derivation output and SHALL need no network. Nix activation on any host SHALL NOT write to a Windows path and SHALL NOT apply any artifact.

#### Scenario: Render the artifacts

- **WHEN** the Windows configuration output is built from the locked repository
- **THEN** the result contains one WinGet Configuration document, one Zen policy script, one native Neo driver script, and the review files that describe their settings
- **AND** the build reads no mutable Windows state

#### Scenario: Evaluate without network

- **WHEN** the flake outputs are evaluated on a machine with no network
- **THEN** the Windows configuration output evaluates
- **AND** the pinned upstream theme files are fetched only when the output is built

#### Scenario: Keep the operating-system boundary

- **WHEN** either host activates a Nix generation
- **THEN** activation writes no file under the Windows user profile
- **AND** activation does not start the Windows apply operation

### Requirement: User scope with explicit machine exceptions

Every document resource SHALL apply in the interactive user's own scope except the Zen package. The official Zen installer SHALL be the only document resource that requests elevation. One Administrator script SHALL own only the Zen policy file under Program Files. The other SHALL own only the native Neo DLLs and keyboard-layout registration. Both scripts SHALL refuse a non-administrator token and SHALL read no Administrator-profile path.

#### Scenario: Apply user-scope resources

- **WHEN** the interactive user applies the document with standard user rights
- **THEN** every resource except the Zen package completes without elevation
- **AND** every other installed application and written file belongs to that user's profile

#### Scenario: Apply the browser exception

- **WHEN** the Zen installer requests the administrator credential and the operator later applies the policy script from an Administrator PowerShell session
- **THEN** both operations write only to the machine-wide Zen installation under Program Files

#### Scenario: Apply the keyboard driver exception

- **WHEN** the operator applies the native Neo script from a 64-bit Administrator PowerShell session
- **THEN** it writes only the checksum-pinned DLLs and `b0000407` machine registration
- **AND** the operator restarts Windows before the document registers input tip `0407:b0000407`

#### Scenario: Reject another privileged declaration

- **WHEN** the document declares another machine-scope package, elevated resource, machine-scope registry value, or Windows feature
- **OR** either Administrator script refers to an interactive-user profile path or a machine path outside its declared ownership
- **THEN** the repository validation fails

### Requirement: Pinned application set

The document SHALL declare one explicit version policy for every application it manages. An exact-pinned application SHALL declare one reviewed version and SHALL install only that version. A self-updating application SHALL omit an exact version and SHALL require the latest version available from its WinGet source. Zed, Brave, and Ferdium SHALL use the self-updating policy because their vendor channels own updates. The document SHALL accept an installed self-updating application when its version is equal to or newer than the latest version in the WinGet source, and SHALL NOT downgrade it. All other applications SHALL remain exact-pinned. The set SHALL cover the operator's confirmed roles: code editor, web browser, Git client, communication client, application launcher with window switching, mouse-driven window move and resize, Neo2 keyboard layout, terminal host, and the terminal font. The document SHALL NOT declare an application that the device management policy already manages.

#### Scenario: Install the declared set

- **WHEN** the operator applies the document on a machine without the declared applications
- **THEN** each exact-pinned application installs at its declared version
- **AND** each self-updating application installs at the latest version available from WinGet
- **AND** each required role has exactly one declared application

#### Scenario: Accept a newer vendor update

- **WHEN** Zed, Brave, or Ferdium has a vendor-channel version newer than the latest version available from WinGet
- **THEN** the document reports that application in the desired state
- **AND** an apply operation does not downgrade or reinstall it

#### Scenario: Detect an unpinned application

- **WHEN** an application declares no version policy, more than one version policy, a version under the self-updating policy, or no version under the exact policy
- **THEN** repository validation fails

#### Scenario: Detect a managed-application conflict

- **WHEN** a declared application appears in the recorded set of centrally managed applications
- **THEN** repository validation fails

### Requirement: Native Ferdium communication client

The rendered Windows application set SHALL declare `Ferdium.Ferdium` as the user-scoped `communication-client` package. The package SHALL run as a native Windows application and SHALL NOT be installed through NixOS, Home Manager, WSLg, or a machine-scoped installer.

#### Scenario: Install Ferdium

- **WHEN** the interactive user applies the rendered Windows configuration without Ferdium installed
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

The document SHALL declare Windows settings by explicit named keys. It SHALL keep the centrally managed Firefox package's interactive-user startup value absent. It SHALL put `en-GB` first in the user's preferred language list and set it as the Windows UI override while the English entry has no input method. It SHALL preserve the existing `de-DE` and `de-AT` entries and their input methods. The `de-DE` entry SHALL list German (Germany) QWERTZ (`0407:00000407`) first and native Neo (`0407:b0000407`) second, before any other input method. German QWERTZ SHALL be the default input method. Native Neo SHALL NOT be the default input method, because Office applications derive character-based shortcuts from the first keyboard layout that Windows loads. The document SHALL disable Windows transparency and animation effects. It SHALL validate dark appearance from application mode, system mode, transparency, and wallpaper. It SHALL NOT depend on the active theme-file path because Windows can store the same declared appearance in `Custom.theme`. For a bundled utility that provides several modules, the document SHALL declare the enabled modules and SHALL also declare every other module as disabled.

#### Scenario: Apply the declared settings

- **WHEN** the operator applies the document
- **THEN** the declared keyboard, file-manager, regional, window-snapping, screenshot-location, and dark-appearance settings match the declaration
- **AND** transparency and animation effects are disabled
- **AND** the short date uses ISO 8601 `yyyy-MM-dd`

#### Scenario: Retain a generated custom theme

- **WHEN** the dark-mode flags, transparency, and wallpaper match the declaration and Windows records them in `Custom.theme`
- **THEN** the dark-appearance resource reports the desired state
- **AND** an apply operation does not rewrite the active theme-file path

#### Scenario: Prevent Firefox from starting at sign-in

- **WHEN** the operator applies the document and signs in again
- **THEN** Firefox does not start through its interactive-user launch-on-login entry
- **AND** the centrally managed Firefox package remains installed

#### Scenario: Separate interface and input languages

- **WHEN** the operator applies the document and signs in again
- **THEN** Windows and PowerToys use English (United Kingdom)
- **AND** the Austrian region and German keyboard layouts remain available
- **AND** no English input method is added
- **AND** German QWERTZ is the default input method and the first keyboard layout that Windows loads
- **AND** native Neo remains available as the second German input method

#### Scenario: Keep standard Office shortcuts

- **WHEN** the operator signs in after the apply and starts Word while German QWERTZ or native Neo is active
- **THEN** `Ctrl+C`, `Ctrl+V`, `Ctrl+F`, `Ctrl+L`, `Ctrl+U`, `Ctrl+D`, `Ctrl+P`, `Ctrl+Q`, and `Ctrl+Y` invoke Word's standard commands
- **AND** no native Neo third-layer character replaces a `Ctrl` letter shortcut

#### Scenario: Reject a native Neo default

- **WHEN** the declaration makes native Neo the default input method or lists it before German QWERTZ
- **THEN** repository validation fails

#### Scenario: Resist an upstream default change

- **WHEN** a bundled utility update would enable a module that the document declares as disabled
- **THEN** the next apply returns that module to the declared state

### Requirement: Application configuration files

The document and companion scripts SHALL declare application configuration in two classes. For an application that does not rewrite its own configuration, the owning artifact SHALL enforce the complete file content. For an application that rewrites its own configuration, the owning artifact SHALL converge only the declared values and SHALL preserve the application's own writes. Zed, Windows Terminal, and Zen SHALL select Catppuccin Mocha from pinned upstream theme data. Zed SHALL select `nixd` from the WSL environment for Nix files and SHALL disable its `nil` fallback. Fork SHALL execute Git inside the NixOS distribution through a checksum-pinned `wslgit` bridge. AltSnap SHALL own modifier-drag movement and 50/50 edge or corner snapping; overlapping PowerToys window-movement modules SHALL remain disabled. ReNeo SHALL run with standalone mode enabled through a reviewed `RunAs` launcher. While German QWERTZ is active, ReNeo SHALL supply every Neo layer in ordinary and elevated applications. While native Neo is active, ReNeo SHALL operate in extension mode, and the native Neo driver SHALL provide the base layout in elevated surfaces.

#### Scenario: Enforce a stable configuration file

- **WHEN** a file in the enforced class differs from the declaration
- **THEN** the apply operation restores the declared content

#### Scenario: Apply the application themes

- **WHEN** the operator applies the document
- **THEN** Zed, Windows Terminal, and Zen select Catppuccin Mocha with Mauve accents
- **AND** each rendered theme matches its pinned upstream source

#### Scenario: Start the Nix language server

- **WHEN** the operator opens a Nix file in a Zed WSL workspace
- **THEN** Zed propagates the locally installed Nix extension through its native WSL transport
- **AND** Zed starts `nixd` from the Linux environment
- **AND** the workflow requires no SSH server

#### Scenario: Run Fork Git operations in WSL

- **WHEN** Fork operates on a repository under `\\wsl.localhost\NixOS`
- **THEN** its pinned Git bridge runs the repository command inside NixOS
- **AND** Fork preserves its other application-owned settings

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

The rendered Windows configuration SHALL keep Zed Vim mode enabled and SHALL declare a user keymap for full editors. In every Vim mode, standard Windows and VS Code `Ctrl` shortcuts SHALL take precedence over Vim's `Ctrl` commands. The standard shortcuts SHALL include copy, cut, paste, select all, undo, redo, save, find, replace, quick open, command palette, new file, open file, recent projects, symbol search, go to line, select next occurrence, dock toggles, and close editor. `Ctrl+K` SHALL remain available as the base keymap's chord prefix. Vim-only single-key `Ctrl` commands that have no selected Windows action SHALL do nothing in a full editor.

The override SHALL NOT change unmodified Vim keys, `Escape`, terminal input, menus, panels, or other non-editor surfaces. The Windows apply operation SHALL converge the declared keymap as complete configuration rather than preserve undeclared keymap entries.

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

- **WHEN** the Windows Zed keymap contains an undeclared binding or differs from the rendered declaration
- **THEN** the apply operation restores the complete declared keymap
- **AND** the next test operation reports the resource in the desired state

### Requirement: Zed WSL LaTeX builds

The rendered Windows Zed user settings SHALL enable TexLab builds when a LaTeX buffer is saved. The setting SHALL apply to LaTeX projects opened through Zed's native WSL workspace transport. Project repositories SHALL retain ownership of their build commands, root-document markers, and LaTeX tool configuration.

#### Scenario: Build a WSL LaTeX project after save

- **WHEN** the operator saves a LaTeX source file in a Zed WSL workspace
- **THEN** Zed sends TexLab a workspace configuration with build-on-save enabled
- **AND** TexLab invokes the WSL project's declared LaTeX build

#### Scenario: Preserve project build ownership

- **WHEN** two LaTeX repositories use different build commands or output directories
- **THEN** each repository supplies those details through its own LaTeX configuration
- **AND** the Windows Zed setting does not embed either repository's paths

### Requirement: Excluded Windows surface

The Windows layer SHALL declare nothing about the taskbar pinned-application list, per-extension default application associations, Night Light CloudStore payloads, or any application that the device management policy manages. The repository SHALL record the reason for each exclusion and the selected manual Night Light state.

#### Scenario: Inspect the excluded surface

- **WHEN** a reader reviews the Windows layer
- **THEN** each exclusion names its reason
- **AND** no part of the layer attempts to set a taskbar pinned-application list, a per-extension association, or a Night Light CloudStore payload
- **AND** the runbook records Night Light as enabled from sunset to sunrise at 50% strength

### Requirement: Validation before and after apply

The repository SHALL validate the rendered document and privilege boundary without a Windows machine. The repository check SHALL validate the shipped document against the WinGet Configuration v3 document contract without rewriting it. The document SHALL carry the schema URL and bare-name dependency form that the WinGet parser recognizes. The operator SHALL test the document and both Administrator scripts before their first apply and SHALL confirm each applied state after the apply.

#### Scenario: Validate without Windows

- **WHEN** the repository checks run on a supported build platform
- **THEN** they validate the shipped document against the document contract, every script against the PowerShell parser, the narrow script boundary, each application's version policy and selector, and the absence of a centrally managed application
- **AND** they require no Windows machine and no network service

#### Scenario: Preserve stable dark appearance acceptance

- **WHEN** Windows records the declared dark modes, transparency, and wallpaper in `Custom.theme`
- **THEN** the live test reports the dark-appearance resource in the desired state
- **AND** the repository check requires no active theme-file path

#### Scenario: Reject a dependency on an undeclared resource

- **WHEN** a resource in the rendered document depends on a name that no resource in the document declares
- **THEN** the repository check fails and names both resources

#### Scenario: Preview and confirm on the machine

- **WHEN** the operator tests the document and both Administrator scripts on the Windows work machine
- **THEN** each test reports drift without applying it
- **AND** later test operations report that the applied state matches all three artifacts

### Requirement: Dedicated browser-relay application

The rendered Windows application set SHALL declare Brave as a self-updating, user-scope Chromium-based browser for OMP browser relay use. The relay browser SHALL have a distinct application role, SHALL NOT replace Zen as the interactive browser, and SHALL NOT appear in the centrally managed application set. The Windows declaration SHALL configure no startup entry for the relay browser.

#### Scenario: Apply the Windows application declaration

- **WHEN** the interactive user applies the rendered Windows configuration without Brave installed
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
- **THEN** no NixOS generation or OMP wrapper change is required
- **AND** the operator can remove the browser-owned relay profile and extension independently

### Requirement: Check expectations derive from the declaration

The Windows configuration output SHALL expose its declaration: the role set, the application list with each version policy and selector, the centrally managed application identifiers, and the review file names. The repository check SHALL read that declaration from the output. It SHALL derive version selectors, roles, elevation, and review-file names from it. The three primary artifact names SHALL come from the fixed Windows output contract. The check SHALL NOT copy mutable pins, palettes, module lists, theme hashes, or review file names. It SHALL keep only invariant rules as literals: schema, unique resource names, dependency existence, elevation and Administrator boundaries, and accepted role identity, policy scope, and ownership rules.

#### Scenario: Change one pin

- **WHEN** a maintainer changes the version or checksum of one exact-pinned application in the declaration and renders the output
- **THEN** the repository check passes with no edit to the check
- **AND** the rendered document carries the new pin

#### Scenario: Declare a self-updating application

- **WHEN** the declaration selects the self-updating policy without a version for Zed, Brave, or Ferdium
- **THEN** the repository check expects `useLatest: true` and no rendered version
- **AND** the check carries no application-specific exception

#### Scenario: Declared application absent from the document

- **WHEN** the declaration lists an application that the rendered document does not carry as exactly one resource with the same identifier, version policy, policy-specific selector, scope, and roles
- **THEN** the repository check fails and names the application

#### Scenario: Rendered version policy differs from the declaration

- **WHEN** an exact resource carries a mismatched version or permits the latest version
- **OR** a self-updating resource carries a version or does not require the latest version
- **THEN** the repository check fails and names the resource

#### Scenario: Review file set differs from the declaration

- **WHEN** the rendered output carries a file that the declaration does not name, or omits one that it names
- **THEN** the repository check fails and names the file

#### Scenario: Reject a different named application

- **WHEN** the declaration replaces the required Zen, Zed, Brave, or Ferdium identity or assigns a policy outside the accepted contract
- **THEN** the repository check fails and names the role
- **AND** the check does not copy a mutable release version or the application's profile data

### Requirement: Every script parses

The repository check SHALL parse every script that the Windows layer ships: each test and set script inside the document, both Administrator scripts, and the ReNeo launcher. The check SHALL use the PowerShell parser for that purpose and SHALL NOT match script source against substrings. The check SHALL assert the Administrator-script boundary on the parsed variable references and string values.

#### Scenario: A script does not parse

- **WHEN** a rendered script contains a syntax error
- **THEN** the repository check fails and names the script and the parser message

#### Scenario: A script refactor keeps the check green

- **WHEN** a maintainer restructures a script without a change to the values it reads or writes
- **THEN** the repository check passes with no edit to the check

### Requirement: Checker errors and self-tests have separate paths

The Windows checker SHALL expose an import-safe `main(argv: Sequence[str] | None = None) -> int` that owns `argparse`. When `argv` is `None`, it SHALL parse `sys.argv[1:]`. Its console script SHALL exit with the returned status. Its normal command SHALL NOT run self-tests. The package build SHALL run its tests from `tests/`. Expected invalid arguments, missing output files, and missing document resources SHALL produce one named finding on stderr and exit 1. These failures SHALL NOT print a traceback or `StopIteration`. Unexpected programming failures SHALL retain a traceback.

#### Scenario: Reject a missing resource

- **WHEN** the document omits a resource that its declaration requires
- **THEN** the command prints one finding that names the missing resource and exits 1
- **AND** it prints no traceback

#### Scenario: Reject bad input

- **WHEN** a caller omits an argument or names a missing output file
- **THEN** the command prints one finding on stderr and exits 1
- **AND** it prints no traceback

#### Scenario: Build and invoke the checker

- **WHEN** the checker package builds
- **THEN** its tests run from `tests/`
- **AND** a later normal checker invocation validates only its supplied output, without running those tests
