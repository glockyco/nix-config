## MODIFIED Requirements

### Requirement: Declared host defaults

Each host SHALL declare its machine identity, interactive user, time zone, locale, and user-visible paths through typed host options. Each host SHALL select its roles through explicit module imports. A platform baseline SHALL read the typed options and SHALL NOT supply a machine-specific default. The WSL host SHALL also declare the login shell and the time and measurement formats that its interactive session uses.

#### Scenario: Inspect the interactive session

- **WHEN** the declared user starts a new interactive session
- **THEN** the session runs the shell that the portable module set configures
- **AND** the prompt, the shared history, and the completion behavior of that set are active

#### Scenario: Report local time and formats

- **WHEN** a host reports the date, the time, and a measured quantity
- **THEN** it uses the host's declared time zone and locale
- **AND** the WSL host uses 24-hour time and metric measurement

#### Scenario: Inspect machine identity

- **WHEN** a host configuration evaluates
- **THEN** its host name and platform display name come from that host's declaration
- **AND** no platform module supplies another machine's name

#### Scenario: Resolve a user-visible path

- **WHEN** a module needs the repository checkout, screenshot directory, share mount point, or package-manager profile path
- **THEN** it derives the path from the typed host or Home Manager configuration
- **AND** it does not embed a user name or an order-dependent mount suffix
