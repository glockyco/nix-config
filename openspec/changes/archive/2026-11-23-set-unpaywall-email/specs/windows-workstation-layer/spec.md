# Spec Delta

## ADDED Requirements

### Requirement: Persistent Unpaywall contact variable

Korolev SHALL hold the current-user environment variable `UNPAYWALL_EMAIL` as an ordinary declared registry setting below `HKCU:\Environment`. Its value SHALL equal the shared contact address of the user configuration, and a declaration test SHALL fail when the two differ.

#### Scenario: Value set by hand before

- **WHEN** the variable already holds the declared address
- **THEN** the engine reports no difference and writes nothing

#### Scenario: Declarations drift apart

- **WHEN** the Windows declaration and the shared contact address differ
- **THEN** the declaration test fails and names the setting
