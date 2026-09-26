## MODIFIED Requirements

### Requirement: Declared host defaults

Each host SHALL derive its name from its host directory and SHALL declare its interactive user, time zone, locale, and applicable user-visible paths through typed options in `hosts/<name>/host.nix`. Each host SHALL select its roles through explicit imports in `hosts/<name>/default.nix`. A platform baseline SHALL read typed host options and SHALL NOT supply another machine's identity or paths. The WSL host SHALL declare the login shell and time and measurement formats for its interactive session.

#### Scenario: Inspect the interactive session

- **WHEN** the declared user starts a new interactive session
- **THEN** the session runs the shell that the portable module set configures
- **AND** the prompt, shared history, and completion behavior of that set are active

#### Scenario: Report local time and formats

- **WHEN** a host reports the date, time, and a measured quantity
- **THEN** it uses its declared time zone and locale
- **AND** the WSL host uses 24-hour time and metric measurement

#### Scenario: Inspect machine identity

- **WHEN** a host configuration evaluates
- **THEN** its host name comes from the typed directory-keyed registry, and its display name, when applicable, comes from host options
- **AND** no platform module supplies another machine's name

#### Scenario: Resolve a user-visible path

- **WHEN** a module needs the repository checkout or screenshot directory
- **THEN** it derives the path from the typed host declaration
- **AND** it does not embed an interactive user name

#### Scenario: Select a host role

- **WHEN** a host selects an optional machine role
- **THEN** its `default.nix` explicitly imports that role
- **AND** the platform baseline does not import the role
