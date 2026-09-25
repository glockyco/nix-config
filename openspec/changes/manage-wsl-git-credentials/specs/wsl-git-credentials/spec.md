## Purpose

Provide persistent, secure HTTPS Git authentication for terminal Git and Fork's WSL Git bridge without managing credentials in a repository.

## ADDED Requirements

### Requirement: Persist HTTPS credentials securely on Korolev

Korolev SHALL provide a Nix-managed credential helper that stores an approved HTTPS Git credential in encrypted, user-owned persistent storage. Configuration and activation SHALL NOT embed a token in a Nix derivation, Git configuration, or plaintext credential file.

#### Scenario: Reuse an enrolled Overleaf credential

- **WHEN** the user has enrolled an Overleaf Git token and subsequently restarts WSL
- **THEN** terminal Git and Fork through `wslgit` can authenticate after unlocking the credential store without re-entering the token

#### Scenario: No enrolled credential

- **WHEN** Git requests a credential that is not enrolled
- **THEN** interactive Git can request a credential from the user
- **AND** non-interactive Git fails without writing an empty or fabricated credential

### Requirement: Keep Windows application ownership separate

The credential setup SHALL NOT install or declare the centrally managed Windows `Git.Git` application. It SHALL leave GitLab SSH authentication unchanged.

#### Scenario: Render workstation configuration

- **WHEN** the Korolev and Windows declarations are evaluated
- **THEN** the credential helper and store provider are present only in the Korolev configuration
- **AND** the Windows application declaration remains unchanged
