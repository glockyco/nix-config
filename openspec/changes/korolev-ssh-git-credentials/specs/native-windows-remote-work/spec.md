## ADDED Requirements

### Requirement: Encrypted Git credentials across Windows logons

Korolev SHALL support Git HTTPS authentication from its standard-account SSH and desktop sessions using current-user encrypted credential storage. Credentials SHALL remain outside declarative configuration and logs. The setup SHALL NOT disable SSH process mitigations or use plaintext credential files.

#### Scenario: Push from a network logon

- **WHEN** the standard account has authenticated locally and pushes a vault commit through plain SSH
- **THEN** Git uses encrypted credentials and the push succeeds without an interactive credential prompt

#### Scenario: Keep desktop Git working

- **WHEN** the same account performs Git HTTPS work in Tern
- **THEN** it uses the same credential store successfully
