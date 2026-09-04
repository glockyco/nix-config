## Purpose

Define how the Darwin host applies state that Nix cannot link from the store: keyboard layouts, Karabiner rules, LaunchServices handlers, symbolic hotkeys, the Terminal.app font, power settings, and Rosetta. Activation reads before it writes, changes only what differs, fails on an unexpected error, and writes nothing in a dry run.

## ADDED Requirements

### Requirement: Activation changes host state only where it differs from the declaration

Each activation concern SHALL read the current host state, compare it with the declared state, and mutate only the part that differs. A second activation of the same generation SHALL change no file, run no reload, and call no platform command that writes. Each concern SHALL report on standard error whether it was current or what it changed.

#### Scenario: Second activation of the same generation

- **WHEN** the user activates a generation that is already active
- **THEN** no file under `~/Library/Keyboard Layouts`, `~/.config/karabiner`, or `~/Applications` changes its content or modification time
- **AND** no `lsregister`, `pmset`, or `defaults import` call runs
- **AND** the activation output reports each concern as current

#### Scenario: Keyboard layout bundle differs

- **WHEN** the installed keyboard layout bundle differs from the bundle in the store
- **THEN** activation replaces the installed bundle
- **AND** activation updates the modification time of the layout directory so macOS recompiles the layouts

#### Scenario: Keyboard layout bundle is current

- **WHEN** the installed keyboard layout bundle has the same content as the bundle in the store
- **THEN** activation leaves the bundle and the layout directory untouched
- **AND** macOS does not recompile the layouts

#### Scenario: Karabiner configuration is current

- **WHEN** the installed `karabiner.json` has the same content as the generated file
- **THEN** activation does not rewrite the file
- **AND** Karabiner-Elements does not reload

#### Scenario: Karabiner configuration differs

- **WHEN** the installed `karabiner.json` differs from the generated file or is absent
- **THEN** activation installs the generated file with mode `0600` in a directory with mode `0700`

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
- **AND** the previous generation stays current

#### Scenario: A preferences domain cannot be read

- **WHEN** `defaults export` for a declared domain exits non-zero
- **THEN** activation fails
- **AND** activation does not import that domain

### Requirement: A Home Manager dry run writes nothing

Each Home Manager activation concern SHALL run through the `run` helper so that a dry run prints the command and executes nothing. A dry run SHALL NOT invoke the packaged program and SHALL change no path that the concern owns.

#### Scenario: Dry run of the user activation

- **WHEN** the user runs the Home Manager activation of a generation with `DRY_RUN` set
- **THEN** the output names each activation program that would run
- **AND** every file and directory owned by those activation concerns remains unchanged

### Requirement: A user agent creates its own data

The PostgreSQL launchd user agent SHALL own its data directory under the primary user's home. Activation SHALL create no directory for a user agent.

#### Scenario: First start on a host without a cluster

- **WHEN** the PostgreSQL agent starts and its data directory does not exist
- **THEN** the agent creates the directory and initialises the cluster with the declared encoding and locale provider
- **AND** the system activation script contains no step for that directory

#### Scenario: Restart with an existing cluster

- **WHEN** the PostgreSQL agent starts and its data directory holds a cluster
- **THEN** the agent serves that cluster unchanged
