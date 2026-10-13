# fleet-tailnet Specification

## Purpose

Connects durable fleet hosts and declared temporary peers over one private tailnet, governs their reachability through tested policy, and gives the Linux host a build path to the Darwin host.

## Requirements

### Requirement: Every declared tailnet member has one identity

Each durable host and temporary peer SHALL join one tailnet with one declared tag and MagicDNS host name. Korolev's sole `tag:korolev` identity SHALL belong to Tailscale for Windows, not WSL. Peer data SHALL declare durability. Repository endpoints SHALL use tailnet names, not LAN addresses or mDNS `.local` names.

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

#### Scenario: Transfer Korolev ownership

- **WHEN** the operator completes the Windows node cutover
- **THEN** exactly one active node owns `korolev` and `tag:korolev`, using Tailscale for Windows
- **AND** the WSL node is logged out/revoked and its daemon is absent
- **AND** device state is not copied between platforms

### Requirement: Declared access policy

Repository-rendered policy SHALL grant every tailnet node access to all ports on declared reachable members, including Windows Korolev, the Mac, desktop and temporary Air. It SHALL generate positive port-22 tests for reachable destinations and deny tests for any declared unreachable fixture/host. It SHALL contain no email addresses or Tailscale SSH authorization. Unreachable/unknown destination assertions and reviewed, separate test/deploy identities SHALL remain effective.

#### Scenario: Render the policy

- **WHEN** the repository renders the policy
- **THEN** the output is a valid policy document with one grant set, tag owners for every declared tag, and network tests
- **AND** it contains no Tailscale SSH rules or SSH tests

#### Scenario: A rule names an unreachable host as a destination

- **WHEN** the declared policy data lists any `reachable = false` host tag as a destination in a grant
- **THEN** evaluation fails

#### Scenario: A rule names the Linux host as a destination

- **WHEN** a policy fixture marks a Linux host unreachable and names that tag as a grant destination
- **THEN** policy evaluation rejects the destination
- **AND** native Windows Korolev's separately reachable machine identity does not authorize a WSL listener

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
- **THEN** GitHub requires a pull request, current Linux, Darwin and Windows checks, and the live policy test from GitHub Actions
- **AND** administrators cannot bypass those protections, create nonlinear history, force-push, or delete main under the configured protection

#### Scenario: Overlapping policy deployments

- **WHEN** multiple successful main checks request policy deployment
- **THEN** apply jobs do not overlap or automatically cancel an in-progress apply
- **AND** a checked revision that is no longer current main is not applied
- **AND** failure to query current main fails the job rather than allowing the write

#### Scenario: Failed native checks

- **WHEN** the main check workflow fails, or the completed workflow was a PR check
- **THEN** no policy apply is authorized by that completion event

#### Scenario: Connect to native Korolev

- **WHEN** the Mac connects to Windows Korolev over the tailnet
- **THEN** policy permits the network path and the separately approved OpenSSH key authenticates
- **AND** this grant does not create a WSL listener or authorize Windows account access by membership alone

#### Scenario: Connect to the Linux host

- **WHEN** another tailnet node attempts to reach a Linux service inside Korolev's secondary WSL environment
- **THEN** WSL supplies no SSH server, tailnet SSH authorization or forwarded service
- **AND** an approved connection to native Windows Korolev remains a separate account/key boundary

#### Scenario: No real unreachable destination remains

- **WHEN** every declared fleet node is reachable
- **THEN** generated tests positively exercise reachable SSH paths instead of carrying empty deny-only tests
- **AND** synthetic unreachable-host fixtures still prove deny generation and forbidden destination rejection

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

The Darwin host SHALL accept SSH through a standard OpenSSH daemon bound only to its tailnet address. It SHALL disable Tailscale SSH and Apple's wildcard Remote Login listener. The Linux Nix daemon SHALL authenticate with a dedicated root-owned client key and verify the server against its declared OpenSSH public host key. The Linux host's interactive user SHALL authenticate with a separate user-owned client key declared as its own labeled authorization entry. The builder key SHALL permit command execution but not forwarding or PTY allocation. The user key SHALL permit command execution and PTY allocation but not forwarding or tunnels. The Darwin authorization file SHALL be a regular root-owned file outside the Nix store, and its canonical parent directories SHALL satisfy OpenSSH strict-mode permissions. SSH SHALL propagate the remote command's exit status without a wrapper.

#### Scenario: Build client connects

- **WHEN** the Linux host's Nix daemon opens an SSH connection to the Darwin host
- **THEN** the dedicated key authenticates as the Darwin host's declared user without a prompt
- **AND** the server reads it from a regular root-owned authorization file whose canonical path does not enter the Nix store
- **AND** the key permits command execution but not forwarding or PTY allocation

#### Scenario: Linux user opens an interactive shell

- **WHEN** the Linux host's interactive user connects to the Darwin host's interactive endpoint
- **THEN** the user-owned key authenticates as the Darwin host's declared user without a password prompt
- **AND** the session receives a terminal, so commands that prompt for local administrator credentials can run
- **AND** port forwarding, agent forwarding, and tunnels are refused

#### Scenario: Revoke the user key

- **WHEN** the owner removes the user key's entry and activates the Darwin host
- **THEN** that key fails to authenticate
- **AND** the builder key still authenticates remote builds

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

### Requirement: Windows Korolev SSH boundary

Korolev SHALL accept key-only OpenSSH Server access to its standard Windows account with the Mac's own revocable source key. Effective listening and firewall settings SHALL restrict SSH to its current tailnet addresses; no broader rule or lost-Tailscale fallback SHALL permit non-tailnet access. Services SHALL not rely on a WSL node or listener.

#### Scenario: Reach native Korolev from the Mac

- **WHEN** the Mac uses its pinned Korolev endpoints
- **THEN** it reaches native Windows with its approved source key and remote exit status 23 is preserved
- **AND** SFTP round-trips a disposable file with matching bytes

#### Scenario: Deny an unapproved path or key

- **WHEN** a source has independently verified non-tailnet reachability and probes SSH there, or presents an unapproved key over Tailscale
- **THEN** the non-tailnet path and unapproved authentication are rejected
- **AND** a changed host key fails client verification without password fallback

#### Scenario: Lose the Windows tunnel

- **WHEN** Tailscale stops or the machine restarts without a usable tailnet address
- **THEN** no wildcard/LAN SSH listener or permissive firewall fallback is introduced
- **AND** access is restored only through the declared tailnet path once the service is available
