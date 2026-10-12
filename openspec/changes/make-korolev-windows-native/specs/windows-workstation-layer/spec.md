## MODIFIED Requirements

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

#### Scenario: Preserve remembered Zed WSL projects

- **WHEN** chezmoi converges existing Zed settings containing `wsl_connections`
- **THEN** remembered WSL projects remain unchanged as app-owned UI state
- **AND** retired declaration-owned nixd/TexLab WSL wiring and the OMP agent server are removed

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

## REMOVED Requirements

### Requirement: Zed WSL LaTeX builds

**Reason**: Windows is the native primary workstation; Windows Zed no longer transports LaTeX projects or TexLab through WSL.
**Migration**: Compile LaTeX with native TeX Live and run TexLab natively, keeping project build commands and root markers in each project. Native Windows document work also uses Typst/tinymist; WSL TeX packages leave with the WSL host and are not a Windows editor dependency.

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

Tern SHALL be installed from the owner's signed-in closed-beta build service into a stable per-user location on PATH and own its updates. Repository configuration SHALL no longer install Windows Terminal or manage its WSL profile. Removing declarations SHALL preserve unrelated terminal profile/session state.

#### Scenario: Launch the primary terminal

- **WHEN** a fresh Windows session resolves and launches Tern
- **THEN** its executable is under the declared stable per-user directory, not a temporary spike folder
- **AND** native PowerShell is usable and WSL is an explicitly selected secondary session
- **AND** clickable links, Unicode/glyphs, paste, resizing and terminal interrupt work without forced environment workarounds
