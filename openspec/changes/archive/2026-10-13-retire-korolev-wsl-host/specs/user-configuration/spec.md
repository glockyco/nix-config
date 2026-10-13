# Spec Delta

## ADDED Requirements

### Requirement: Checkout and machine selection

Each machine's chezmoi configuration SHALL record its own stable checkout as sourceDir and explicit data.host, using home as source root. Destinations SHALL stay outside sourceDir; apply SHALL require no second clone or hostname inference. Mac Darwin and Korolev Windows platform facts SHALL select distinct users/paths. Retired Korolev Linux facts SHALL be absent.

#### Scenario: Initialize an existing checkout

- **WHEN** chezmoi initializes from the local reviewed checkout
- **THEN** subsequent apply uses that checkout and explicit machine data
- **AND** initialization stays separate from apply for preview

#### Scenario: Select the supported platform

- **WHEN** Korolev initializes chezmoi from its native checkout
- **THEN** Windows-qualified facts select its standard user/home/source paths
- **AND** no Linux platform data or UNC NixOS source supplies user configuration

## MODIFIED Requirements

### Requirement: One owner for each user destination

Chezmoi SHALL own managed user files/setup from home; platform configuration SHALL own packages/system preferences/services. Home Manager SHALL own no scope. App/OMP mutable state, private keys and project data SHALL stay outside whole-file replacement ownership. Mac and native Windows SHALL be the supported platforms; no Korolev/Linux user source or setup SHALL remain.

#### Scenario: Inspect a managed host

- **WHEN** a supported workstation's configuration is built or natively applied
- **THEN** every declared user destination has one owner and no Home Manager integration exists

#### Scenario: Render platform-specific setup

- **WHEN** native Windows applies the shared source
- **THEN** no Darwin-only user file/helper/credential or Linux setup is applied
- **AND** applicable shared Git/CLI configuration remains available

#### Scenario: Retain secondary workstation tools

- **WHEN** the Mac configuration is built and native Windows configuration is applied
- **THEN** the Mac retains Herdr, Ghostty's host cask/Dock and chezmoi theme/settings
- **AND** Herdr integration remains an explicit Mac owner operation, never an activation/chezmoi-owned OMP file
- **AND** no retired WSL secondary tool package set remains

### Requirement: Private age credentials remain host-local

Managed Mac credentials SHALL use private whole-file age sources and private destination permissions. The Mac SHALL retain its own age identity. Conversion/decryption SHALL keep plaintext out of repository/store/output and other hosts, with its at-rest trade-off documented. Native Windows SHALL exclude Mac secrets without a separately approved key enrollment; retirement SHALL transfer no credentials or identities.

#### Scenario: Convert existing credentials

- **WHEN** the Mac migrates Fastmail and Cloudflare DNS/Workers credentials
- **THEN** only ciphertext enters tracked source and the existing identity decrypts replacements before old ciphertext retires

#### Scenario: Apply credentials and verify consumers

- **WHEN** the Mac applies encrypted source
- **THEN** destination files have mode 0600 in a private directory
- **AND** Fastmail and opt-in direnv helpers use new paths without printing values

#### Scenario: Apply on another platform

- **WHEN** native Windows applies without separately enrolled key access
- **THEN** Mac credential sources are excluded
- **AND** no Mac token, private age identity or WSL authentication file is copied

### Requirement: System switch precedes user apply

The Mac switch command SHALL finish its authorized system switch before ordinary-user chezmoi apply. Windows SHALL use its native user setup without a Nix system switch. System failure SHALL prevent subsequent user apply; user failure SHALL be reported as a partial operation, not hidden or automatically rolled back. Retained generations/source backups SHALL support explicit recovery.

#### Scenario: Switch succeeds

- **WHEN** an authorized Mac system switch completes
- **THEN** user apply resolves helpers/resources from that generation and runs without root-owned user destinations

#### Scenario: A phase fails

- **WHEN** system switch or user apply fails
- **THEN** the operation exits unsuccessfully naming the phase
- **AND** retained generations/local backups remain available

### Requirement: Acceptance proves actual consumer behavior

User-configuration acceptance SHALL require applicable Mac/CI builds/checks, native Windows checks, chezmoi verify on each affected actual host and real consumer smokes. Agents MAY run authorized Mac activation in a terminal while the owner types sudo credentials; agents SHALL not obtain passwords. Publication/merges SHALL require explicit owner approval. No retired-host check SHALL substitute for native Windows verification.

#### Scenario: Accept both live hosts

- **WHEN** reviewed source has been applied on Mac and native Windows
- **THEN** applicable shell/Git/SSH/credential consumers pass on their real hosts
- **AND** Mac keyboard/Karabiner/default-app/screenshot/Colima behavior remains accepted
- **AND** both pass chezmoi verify and repeated apply without unexpected writes

#### Scenario: Static checks pass without live access

- **WHEN** only evaluation/build/sandbox checks have passed
- **THEN** acceptance remains incomplete until owner-assisted live apply and consumer verification finish

## REMOVED Requirements

### Requirement: Local source and machine selection

**Reason**: Its scenario about Windows and WSL sharing a machine name describes a retired host.
**Migration**: Use `Checkout and machine selection`, which keeps sourceDir, explicit data.host and distinct Mac and Windows platform facts.
