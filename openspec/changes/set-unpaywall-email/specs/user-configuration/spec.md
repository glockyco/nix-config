# Spec Delta

## ADDED Requirements

### Requirement: Shared Unpaywall contact environment

Both managed hosts, macbook-pro and native Windows korolev, SHALL provide `UNPAYWALL_EMAIL` as `johann.glock@scch.at` to programs started by OMP in a fresh Tern session after user configuration is applied. The contact SHALL have one shared non-secret declaration and SHALL require no Unpaywall account or address typed into a command.

#### Scenario: Start research on the Mac

- WHEN reviewed user configuration has been applied on macbook-pro and a fresh OMP session starts in Tern
- THEN a child command that prints the inherited `UNPAYWALL_EMAIL` prints the declared contact
- AND the contact is available in non-interactive zsh commands as well as interactive shells

#### Scenario: Start research on native Windows

- WHEN reviewed user configuration has been applied on korolev and a fresh OMP session starts in Tern with the refreshed user environment
- THEN an OMP child command that prints the inherited `UNPAYWALL_EMAIL` prints the declared contact without loading a PowerShell profile

#### Scenario: Change the common contact

- WHEN the shared contact declaration changes and configuration is reapplied on both hosts
- THEN fresh consumer sessions on both hosts use the changed value without editing a second address literal

#### Scenario: Preserve unrelated configuration

- WHEN the Unpaywall environment declaration is applied
- THEN no unrelated environment value, application, configuration or runtime state is removed
- AND neither OMP nor its plugins or Tern are installed or reconfigured by this change
