## ADDED Requirements

### Requirement: Vault commit tools on the Mac

The Mac SHALL install `gitleaks` and `lefthook` as user packages, so that the notes vault's clone in `~/notes` can run its pre-commit secret scan like Korolev's.

#### Scenario: Commit in the Mac vault

- **WHEN** a session commits in `~/notes` after activation
- **THEN** the vault's pre-commit hook runs `gitleaks` through `lefthook` from PATH
