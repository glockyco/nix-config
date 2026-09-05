## Purpose

Connects durable fleet hosts and declared temporary peers over one private tailnet, governs their reachability through tested policy, and gives the Linux host a build path to the Darwin host.

## ADDED Requirements

### Requirement: Every declared tailnet member has one identity

Each durable fleet host and temporary peer SHALL join one tailnet as a node with exactly one declared tag. A peer declaration SHALL state whether the peer is durable or temporary. The MagicDNS name of a node SHALL be its host name. Repository configuration SHALL address a tailnet member by its tailnet name and SHALL NOT address it by an mDNS `.local` name or by a LAN address.

#### Scenario: Reach a machine from another network

- **WHEN** two fleet machines are on different physical networks and both are connected to the tailnet
- **THEN** each machine that the policy permits resolves the other by its tailnet name and connects to it

#### Scenario: A managed host declares no tag

- **WHEN** a managed host configuration omits its tailnet tag
- **THEN** evaluation fails with an error that names the option

#### Scenario: A durable tagged node remains connected

- **WHEN** a durable fleet host has been connected for longer than the default key expiry
- **THEN** its tagged node remains connected without re-authentication

#### Scenario: Inspect a temporary peer declaration

- **WHEN** a maintainer inspects the Air peer
- **THEN** its declaration identifies it as temporary and states its research-results purpose
- **AND** no durable builder, storage, authentication, or release gate depends on it

#### Scenario: Temporary peer metadata is incomplete

- **WHEN** a temporary peer omits its lifecycle or purpose
- **THEN** policy rendering fails and names that peer

### Requirement: Declared access policy

The tailnet access policy SHALL be declared as repository data and rendered by the repository. The rendered policy SHALL permit every node to reach the Darwin host, the desktop, and the Air while the Air is declared. It SHALL permit the Linux host to reach those declared destinations. No rule SHALL name the Linux host as a destination. The rendered policy SHALL contain no e-mail address. The rendered policy SHALL contain Tailscale network tests that deny TCP port 22 to the Linux host from every other node. Renderer assertions SHALL prevent access rules from naming the Linux host as a destination. The policy SHALL contain no Tailscale SSH authorization; OpenSSH SHALL own SSH authentication.

#### Scenario: Render the policy

- **WHEN** the repository renders the policy
- **THEN** the output is a valid policy document with one grant set, tag owners for every declared tag, and network tests
- **AND** it contains no Tailscale SSH rules or SSH tests

#### Scenario: A rule names the Linux host as a destination

- **WHEN** the declared policy data lists the Linux host's tag as a destination in any grant
- **THEN** evaluation fails

#### Scenario: A rule carries an e-mail address

- **WHEN** the declared policy data contains an `@` character
- **THEN** evaluation fails

#### Scenario: Apply a reviewed policy

- **WHEN** a pull request changes the policy data
- **THEN** continuous integration renders the policy and runs the tailnet's policy tests with read-only provider authorization
- **AND** a successful main push check permits deployment of that exact checked revision through a separate write identity
- **AND** the write identity rejects PR-issued tokens and constrains the repository, main ref, and deployment workflow

#### Scenario: Main protection

- **WHEN** a change is proposed for main
- **THEN** GitHub requires a pull request, current Linux and Darwin checks, and the live policy test from GitHub Actions
- **AND** administrators cannot bypass those protections, create nonlinear history, force-push, or delete main under the configured protection

#### Scenario: Overlapping policy deployments

- **WHEN** multiple successful main checks request policy deployment
- **THEN** apply jobs do not overlap or automatically cancel an in-progress apply
- **AND** a checked revision that is no longer current main is not applied
- **AND** failure to query current main fails the job rather than allowing the write

#### Scenario: Failed native checks

- **WHEN** the main check workflow fails, or the completed workflow was a PR check
- **THEN** no policy apply is authorized by that completion event

#### Scenario: Connect to the Linux host

- **WHEN** any other node attempts a connection to the Linux host's tailnet address
- **THEN** the connection is refused by policy

### Requirement: Temporary peers leave no durable dependency

A temporary peer SHALL serve only its declared short-term purpose. Durable builders, storage, authentication, activation, and release gates SHALL operate without that peer. The owning repository SHALL track one clean removal procedure in an offboarding issue outside the active change.

#### Scenario: Remove the Air declaration

- **WHEN** a policy fixture removes the temporary Air peer
- **THEN** the rendered tag owners, grants, and tests contain no Air tag
- **AND** the durable three-machine topology still satisfies every policy invariant

#### Scenario: Return the borrowed Air

- **WHEN** the owner no longer needs the Air's research results
- **THEN** the required results are preserved before the machine leaves
- **AND** the node is revoked before the machine is returned
- **AND** its tag, policy entries, SSH and SMB endpoints, local credentials, role, and declaration are removed

### Requirement: Tailnet SSH access to the Darwin host

The Darwin host SHALL accept SSH through a standard OpenSSH daemon bound only to its tailnet address. It SHALL disable Tailscale SSH and Apple's wildcard Remote Login listener. The Linux Nix daemon SHALL authenticate with a dedicated root-owned client key and verify the server against its declared OpenSSH public host key. SSH SHALL propagate the remote command's exit status without a wrapper.

#### Scenario: Build client connects

- **WHEN** the Linux host's Nix daemon opens an SSH connection to the Darwin host
- **THEN** the dedicated key authenticates as the Darwin host's declared user without a prompt
- **AND** the key permits command execution but not forwarding or PTY allocation

#### Scenario: An unapproved key connects

- **WHEN** a tailnet device attempts SSH without a declared authorized key
- **THEN** authentication fails, even if tailnet policy permits its network connection

#### Scenario: Host key verification

- **WHEN** the server presents a key different from the declared OpenSSH host key
- **THEN** the client refuses the connection without prompting or accepting the replacement

#### Scenario: Tailnet-only listening

- **WHEN** the configured SSH daemon runs
- **THEN** it listens only on addresses resolved from the Mac's full MagicDNS name
- **AND** neither Tailscale SSH nor Apple's wildcard Remote Login listener is enabled
- **AND** failure to resolve or bind the tailnet address does not create a wildcard or LAN listener

#### Scenario: Remote command fails

- **WHEN** a remote command exits with status 23
- **THEN** the native SSH client returns status 23

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
