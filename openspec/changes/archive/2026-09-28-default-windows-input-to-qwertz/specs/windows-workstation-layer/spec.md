## MODIFIED Requirements

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
