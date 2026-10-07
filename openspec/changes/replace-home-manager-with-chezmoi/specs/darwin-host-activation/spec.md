# Spec Delta

## MODIFIED Requirements

### Requirement: Activation changes host state only where it differs from the declaration

System activation SHALL retain power/Rosetta ownership; chezmoi change scripts SHALL invoke packaged helpers for layouts, handlers, shortcuts and Terminal fonts, and modify templates SHALL merge declared Karabiner settings. Each invoked concern SHALL compare before writing, mutate only declared differences and report current or changed state. Reapplying unchanged user source SHALL perform no user setup writes.

The user-helper scenarios below apply when a source change schedules the helper or an operator explicitly reruns it for recovery. Unchanged change scripts SHALL NOT be treated as an external-preference drift scheduler.

#### Scenario: Second activation of the same generation

- **WHEN** the user activates a generation that is already active
- **THEN** no file under `~/Library/Keyboard Layouts`, `~/.config/karabiner`, or `~/Applications` changes its content or modification time
- **AND** no `lsregister`, `pmset`, or `defaults import` call runs
- **AND** invoked helper output reports current state and unchanged chezmoi change scripts are skipped

#### Scenario: Keyboard layout bundle differs

- **WHEN** the installed keyboard layout bundle differs from the bundle in the store
- **THEN** activation replaces the installed bundle
- **AND** activation updates the modification time of the layout directory so macOS recompiles the layouts

#### Scenario: Keyboard layout bundle is current

- **WHEN** the installed keyboard layout bundle has the same content as the bundle in the store
- **THEN** activation leaves the bundle and the layout directory untouched
- **AND** macOS does not recompile the layouts

#### Scenario: Karabiner configuration is current

- **WHEN** the installed `karabiner.json` has the same declared managed settings as the modify template
- **THEN** activation does not rewrite the file
- **AND** Karabiner-Elements does not reload

#### Scenario: Karabiner configuration differs

- **WHEN** the installed `karabiner.json` has different declared managed settings or is absent
- **THEN** chezmoi merges the declared settings while preserving unrelated profiles and rules, with mode `0600` in a directory with mode `0700`

#### Scenario: File-type bundle is current

- **WHEN** the installed `FileTypes.app` has the same content as the bundle in the store
- **THEN** activation does not replace the bundle
- **AND** activation does not run `lsregister`

#### Scenario: File-type bundle differs

- **WHEN** the installed `FileTypes.app` differs from the bundle in the store or is absent
- **THEN** activation replaces the bundle
- **AND** activation registers the new bundle with LaunchServices once

#### Scenario: Handler binding is current

- **WHEN** LaunchServices already reports the declared application for a type, extension, or URL scheme
- **THEN** activation does not bind that type, extension, or scheme

#### Scenario: Symbolic hotkeys are current

- **WHEN** every declared shortcut identifier is already disabled in the `com.apple.symbolichotkeys` domain
- **THEN** activation does not import the domain

#### Scenario: Symbolic hotkey differs

- **WHEN** a declared shortcut identifier is enabled or absent in the `com.apple.symbolichotkeys` domain
- **THEN** activation imports the domain once with that identifier disabled
- **AND** every other entry of the domain keeps its value

#### Scenario: Terminal font is current

- **WHEN** every profile that Terminal.app opens with already names the declared font
- **THEN** activation does not import the `com.apple.Terminal` domain

#### Scenario: Terminal font differs

- **WHEN** a profile that Terminal.app opens with names another font
- **THEN** activation imports the domain once with the declared font in that profile
- **AND** the profile keeps its font size

#### Scenario: Power settings are current

- **WHEN** `pmset` reports the declared sleep and display-sleep values for both power sources
- **THEN** activation calls no `pmset` command that writes

#### Scenario: Power setting differs

- **WHEN** `pmset` reports a value for one power source that differs from the declaration
- **THEN** activation writes the declared values for that power source only

#### Scenario: Rosetta is present

- **WHEN** an `x86_64` executable runs on the host
- **THEN** activation does not call `softwareupdate`

#### Scenario: Rosetta is absent

- **WHEN** an `x86_64` executable cannot run on the host
- **THEN** activation installs Rosetta with the licence accepted

### Requirement: Activation fails on an unexpected error

An activation concern SHALL exit non-zero, and activation SHALL stop, when a platform command fails for a reason the concern does not document. A concern SHALL tolerate a documented failure only where the declaration records why the failure is expected.

#### Scenario: LaunchServices refuses a binding for an undocumented reason

- **WHEN** `duti` fails to bind a type with a result other than `-50`
- **THEN** activation fails
- **AND** the output names the application, the type, and the result

#### Scenario: LaunchServices refuses a dynamic type

- **WHEN** `duti` fails to bind a type with result `-50`
- **THEN** activation continues
- **AND** the output names the type that macOS resolved to a dynamic identifier

#### Scenario: Rosetta installation fails

- **WHEN** Rosetta is absent and `softwareupdate` exits non-zero
- **THEN** activation fails

#### Scenario: A preferences domain cannot be read

- **WHEN** `defaults export` for a declared domain exits non-zero
- **THEN** activation fails
- **AND** activation does not import that domain

## ADDED Requirements

### Requirement: A chezmoi dry run writes nothing

A user configuration dry run SHALL show the planned file and setup changes without executing setup helpers or changing destination state. It SHALL NOT print decrypted credential contents into recorded output.

#### Scenario: Dry run of the user activation

- **WHEN** the user previews ordinary configuration with chezmoi dry-run mode
- **THEN** pending user changes are shown without executing packaged setup helpers
- **AND** every file, directory and preference owned by those concerns remains unchanged

#### Scenario: Preview a secret change safely

- **WHEN** an operator inspects encrypted credential changes
- **THEN** the preview records only source/path and permission metadata, not decrypted values

## REMOVED Requirements

### Requirement: A Home Manager dry run writes nothing

**Reason**: Home Manager activation and its run helper are removed.
**Migration**: Preview user changes with chezmoi dry-run mode, exclude secret contents from recorded diffs, and verify helper nonexecution against fixtures.
