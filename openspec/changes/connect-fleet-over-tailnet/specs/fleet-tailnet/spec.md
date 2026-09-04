## Purpose

Connects the fleet machines over one private tailnet with stable names, governs which machine may reach which through a declared and tested access policy, and gives the Linux host a build path to the Darwin host.

## ADDED Requirements

### Requirement: Every fleet machine is a tagged tailnet node

Each fleet machine SHALL join one tailnet as a node with exactly one declared tag. The MagicDNS name of a node SHALL be its host name. Repository configuration SHALL address a fleet machine by its tailnet name and SHALL NOT address it by an mDNS `.local` name or by a LAN address.

#### Scenario: Reach a machine from another network

- **WHEN** two fleet machines are on different physical networks and both are connected to the tailnet
- **THEN** each machine that the policy permits resolves the other by its tailnet name and connects to it

#### Scenario: A managed host declares no tag

- **WHEN** a managed host configuration omits its tailnet tag
- **THEN** evaluation fails with an error that names the option

#### Scenario: A node key does not expire

- **WHEN** a fleet machine has been connected to the tailnet for longer than the default key expiry
- **THEN** it remains connected without re-authentication

### Requirement: Declared access policy

The tailnet access policy SHALL be declared as repository data and rendered by the repository. The rendered policy SHALL permit every node to reach the Darwin host, the Air, and the desktop, and SHALL permit the Linux host to reach those three. No rule SHALL name the Linux host as a destination. The rendered policy SHALL contain no e-mail address. The rendered policy SHALL contain Tailscale tests that assert the Linux host is unreachable from every other node.

#### Scenario: Render the policy

- **WHEN** the repository renders the policy
- **THEN** the output is a valid policy document with one grant set, one SSH rule set, tag owners for every declared tag, and network and SSH tests

#### Scenario: A rule names the Linux host as a destination

- **WHEN** the declared policy data lists the Linux host's tag as a destination in any grant or SSH rule
- **THEN** evaluation fails

#### Scenario: A rule carries an e-mail address

- **WHEN** the declared policy data contains an `@` character
- **THEN** evaluation fails

#### Scenario: Apply a reviewed policy

- **WHEN** a pull request changes the policy data
- **THEN** continuous integration renders the policy and runs the tailnet's policy tests without applying it
- **AND** the merge to the main branch renders the policy again and applies it

#### Scenario: Connect to the Linux host

- **WHEN** any other node attempts a connection to the Linux host's tailnet address
- **THEN** the connection is refused by policy

### Requirement: Tailnet SSH access to the Darwin host

The Darwin host SHALL accept SSH connections from the tailnet through the tailnet's SSH server and SHALL NOT run the platform SSH server. The Linux host SHALL connect as the Darwin host's interactive user without a prompt and without a client private key. The owner's other devices SHALL connect as that user only after re-authentication in check mode.

#### Scenario: Build client connects

- **WHEN** the Linux host's Nix daemon opens an SSH connection to the Darwin host
- **THEN** the session is authenticated by tailnet identity, runs as the Darwin host's interactive user, and requires no key file on the Linux host

#### Scenario: Owner connects from another device

- **WHEN** the owner connects from the Air or the desktop
- **THEN** the tailnet requires re-authentication within its check period before the session opens

#### Scenario: Host key verification

- **WHEN** an SSH client on the Linux host connects to the Darwin host
- **THEN** it verifies the host key against the key that the tailnet control plane distributes for that node
- **AND** no host key literal exists in the repository

#### Scenario: Remote Login stays off

- **WHEN** the Darwin host configuration is inspected
- **THEN** Apple's SSH server is not enabled

### Requirement: Darwin remote builder for the Linux host

The Linux host SHALL declare the Darwin host as a remote builder for `aarch64-darwin`. A build of an `aarch64-darwin` derivation requested on the Linux host SHALL run on the Darwin host and return its output to the Linux host. The Darwin host SHALL accept the imported store paths of the build client's user.

#### Scenario: Build a Darwin check from the Linux host

- **WHEN** the operator runs `nix build` for an `aarch64-darwin` check on the Linux host
- **THEN** the derivation builds on the Darwin host and the output is present in the Linux host's store

#### Scenario: Live builder check

- **WHEN** the operator runs the documented builder check on the Linux host while the Darwin host is connected
- **THEN** the check builds a derivation that records the building machine and confirms that the Darwin host built it

#### Scenario: Darwin host unreachable

- **WHEN** the Darwin host is not connected to the tailnet
- **THEN** a build that requires it fails within the declared connection timeout with a message that names the builder
