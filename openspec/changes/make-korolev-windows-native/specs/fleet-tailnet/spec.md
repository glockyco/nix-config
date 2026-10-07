## MODIFIED Requirements

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

- **WHEN** the Mac or desktop connects to Windows Korolev over the tailnet
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

## ADDED Requirements

### Requirement: Windows Korolev SSH boundary

Korolev SHALL accept key-only OpenSSH Server access to its standard Windows account with independently revocable Mac and desktop source keys. Effective listening and firewall settings SHALL restrict SSH to its current tailnet addresses; no broader rule or lost-Tailscale fallback SHALL permit non-tailnet access. Services SHALL not rely on a WSL node or listener.

#### Scenario: Reach native Korolev from each durable source

- **WHEN** the Mac and desktop use their pinned Korolev endpoints
- **THEN** each reaches native Windows with its own approved source key and remote exit status 23 is preserved
- **AND** SFTP round-trips a disposable file with matching bytes
- **AND** revoking one source key does not revoke the other

#### Scenario: Deny an unapproved path or key

- **WHEN** a source has independently verified non-tailnet reachability and probes SSH there, or presents an unapproved key over Tailscale
- **THEN** the non-tailnet path and unapproved authentication are rejected
- **AND** a changed host key fails client verification without password fallback

#### Scenario: Lose the Windows tunnel

- **WHEN** Tailscale stops or the machine restarts without a usable tailnet address
- **THEN** no wildcard/LAN SSH listener or permissive firewall fallback is introduced
- **AND** access is restored only through the declared tailnet path once the service is available

### Requirement: WSL uses the Windows tailnet transport

WSL SHALL retain root-only Darwin-builder authentication and pinned server verification while routing through Windows Tailscale and Windows DNS tunneling. A separate WSL Tailscale daemon, device identity, port proxy or public service SHALL not be required. Native Windows user SSH SHALL never use the root builder key.

#### Scenario: Build through the Windows tunnel

- **WHEN** the WSL Nix daemon requests a fresh Darwin derivation after cutover and a coordinated WSL restart
- **THEN** MagicDNS resolves the Mac, the root-owned builder key authenticates and the Mac builds the nonce-bearing output
- **AND** public DNS and applicable employer DNS continue to resolve
- **AND** no duplicate Linux Tailscale node is needed
