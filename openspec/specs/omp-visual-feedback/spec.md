## Purpose

Provide browser-based visual feedback on documents and assistant responses in a local upstream OMP session, without adding a planning or approval workflow.

## Requirements

### Requirement: Unmodified vendor package delivery

Each host SHALL use unmodified vendor Plannotator through its declared platform owner, without a local lease patch or separate package recipe. Application advancement SHALL require an explicit reviewed platform source/release change and verification of the command-line tool. Delivery SHALL not require an upstream contribution, custom CI caching or a cross-host Nix package. Version provenance SHALL be recorded independently for both native installations.

#### Scenario: Select the vendor package

- **WHEN** both hosts resolve their annotation executable
- **THEN** the Mac selects its unmodified pinned vendor package and Windows its accepted official release
- **AND** browser, network, lifecycle, activation and recovery acceptance remain required

#### Scenario: Update the selected package

- **WHEN** an explicit Plannotator update changes the Mac source revision or Windows release selection
- **THEN** review verifies that the command-line tool annotates a document on affected hosts
- **AND** routine complete flake lock updates cannot advance the declared Mac application source

### Requirement: Official OMP plugin delivery

Both hosts SHALL annotate through Plannotator's own OMP plugin, `@plannotator/pi-extension`, installed at a reviewed exact version with OMP's user plugin manager by the documented command. Advancing its version SHALL be an explicit reviewed change. The personal plugin SHALL register no annotation commands that could shadow it.

#### Scenario: Annotate in a fresh session

- **WHEN** the user starts OMP after installing the documented plugin version
- **THEN** `/plannotator-annotate` and `/plannotator-last` come from Plannotator's plugin
- **AND** reviews opened by them or by the plugin's agent tool return their feedback to the session

### Requirement: Plannotator sharing is off

Each host's `~/.plannotator/config.json` SHALL set `share` to `disabled` and keep every other setting it holds. The plugin's agent tool and its default feedback text SHALL stay as Plannotator ships them.

#### Scenario: Apply user configuration

- **WHEN** chezmoi applies the user configuration on either host
- **THEN** the configuration file disables sharing
- **AND** settings saved from Plannotator's own settings page remain
