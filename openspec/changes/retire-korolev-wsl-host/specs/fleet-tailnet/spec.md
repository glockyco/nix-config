# Spec Delta

## MODIFIED Requirements

### Requirement: Every declared tailnet member has one identity

Each durable host and temporary peer SHALL join one tailnet with one declared tag and MagicDNS host name. Korolev's sole tag:korolev identity SHALL remain Tailscale for Windows. Removing its Nix host SHALL retain its durable native policy membership through peer data. Peer data SHALL declare durability. Repository endpoints SHALL use tailnet names, not LAN addresses or mDNS .local names.

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

- **WHEN** the operator retires Korolev's Nix host after the Windows node cutover
- **THEN** exactly one active Windows node retains korolev and tag:korolev
- **AND** its durable peer membership remains without a duplicate Nix host entry
- **AND** no device state is copied between platforms

## ADDED Requirements

### Requirement: Declared native fleet access policy

Repository-rendered policy SHALL grant every tailnet node access to declared reachable members, including native Windows Korolev, the Mac, desktop and temporary Air. It SHALL generate positive port-22 tests and synthetic unreachable-destination rejection tests. It SHALL contain no email addresses or Tailscale SSH authorization. Reviewed separate test/deploy identities and protected-main acceptance SHALL remain effective; no retired host gate SHALL authorize deployment.

#### Scenario: Render the policy

- **WHEN** the repository renders the policy
- **THEN** the output is a valid policy document with one grant set, tag owners for every declared tag, and network tests
- **AND** it contains no Tailscale SSH rules or SSH tests

#### Scenario: A rule names an unreachable host as a destination

- **WHEN** policy data lists any reachable = false host tag as a destination in a grant
- **THEN** evaluation fails

#### Scenario: A rule names an unreachable fixture as a destination

- **WHEN** a synthetic policy fixture marks a host unreachable and names that tag as a grant destination
- **THEN** policy evaluation rejects the destination
- **AND** no real Korolev/Linux host is required to prove this invariant

#### Scenario: A rule carries an e-mail address

- **WHEN** declared policy data contains an @ character
- **THEN** evaluation fails

#### Scenario: Apply a reviewed policy

- **WHEN** a pull request changes the policy data
- **THEN** CI renders policy and runs live policy tests with read-only provider authorization
- **AND** successful required checks on the exact main revision permit deployment through a separate write identity
- **AND** that identity rejects PR-issued tokens and constrains the repository, main ref and deployment workflow

#### Scenario: Main protection

- **WHEN** a change is proposed for main
- **THEN** GitHub requires a pull request, current Darwin, Linux-generic, Windows and portable OpenSpec checks, and the live policy test
- **AND** administrators cannot bypass protection, create nonlinear history, force-push or delete main

#### Scenario: Overlapping policy deployments

- **WHEN** multiple successful main checks request policy deployment
- **THEN** apply jobs do not overlap or automatically cancel an in-progress apply
- **AND** a checked revision no longer current main is not applied
- **AND** failure to query current main fails rather than allowing the write

#### Scenario: Failed native checks

- **WHEN** a required check fails, including portable OpenSpec, or the completed workflow was a PR check
- **THEN** no policy apply is authorized by that completion event

#### Scenario: Connect to native Korolev

- **WHEN** the Mac or desktop connects to Windows Korolev over the tailnet
- **THEN** policy permits the network path and its independently approved OpenSSH key authenticates
- **AND** membership alone does not authorize Windows account access

#### Scenario: Retire the Linux host

- **WHEN** the NixOS distribution and its host declaration are retired
- **THEN** no Linux host identity, service or policy dependency remains
- **AND** native Windows Korolev remains reachable only through its approved native service/account boundaries

#### Scenario: No real unreachable destination remains

- **WHEN** every declared fleet node is reachable
- **THEN** generated tests positively exercise reachable SSH paths instead of carrying empty deny-only tests
- **AND** synthetic unreachable-host fixtures still prove deny generation and forbidden destination rejection

### Requirement: Native user SSH access to the Darwin host

The Darwin host SHALL accept standard key-only OpenSSH on its tailnet addresses, with Tailscale SSH and wildcard Remote Login disabled. Native Windows user access SHALL use an independently approved user key, pinned host verification and no forwarding/tunnels. The authorization file SHALL remain a regular root-owned file outside the Nix store with StrictModes-compatible parents. The retired Nix-daemon builder authorization and its non-root Nix trust SHALL be removed.

#### Scenario: Retired build client connects

- **WHEN** the retired Linux daemon builder key attempts to authenticate after approved Mac activation
- **THEN** the Mac rejects that key
- **AND** its former SSH login user no longer receives Nix import trust solely for that builder

#### Scenario: Native Windows user opens an interactive shell

- **WHEN** Korolev's native Windows user connects to macbook-pro
- **THEN** its independently approved user key authenticates as the declared Mac user with a terminal
- **AND** local sudo prompts remain owner-typed and operation-authorized
- **AND** port forwarding, agent forwarding and tunnels are refused
- **AND** the server reads a regular root-owned authorization file outside the Nix store

#### Scenario: Revoke the user key

- **WHEN** the owner removes a native user key's entry and authorizes Darwin activation
- **THEN** that key fails to authenticate
- **AND** unrelated approved source keys retain their access

#### Scenario: An unapproved key connects

- **WHEN** a tailnet device attempts SSH without a declared authorized key
- **THEN** authentication fails even if tailnet policy permits its network connection

#### Scenario: Host key verification

- **WHEN** the server presents a key different from the declared OpenSSH host key
- **THEN** the client refuses without prompting or accepting the replacement

#### Scenario: Tailnet-only listening

- **WHEN** the configured SSH daemon runs
- **THEN** it listens only on addresses resolved from the Mac's full MagicDNS name
- **AND** neither Tailscale SSH nor Apple's wildcard Remote Login listener is enabled
- **AND** failure to resolve or bind creates no wildcard or LAN listener

#### Scenario: Remote command fails

- **WHEN** a remote command exits with status 23
- **THEN** the native SSH client returns status 23

## REMOVED Requirements

### Requirement: Darwin remote builder for the Linux host

**Reason**: No Korolev Linux Nix daemon remains after the Windows-only cutover.
**Migration**: Run Nix evaluation/build/activation on the Mac and applicable CI. Remove root client key/path/pin declarations, tailnet-builder-check and only the matching Mac builder authorization/trust; retain native Windows user SSH.

### Requirement: Declared access policy

**Reason**: The former requirement includes active Linux-host destination and connectivity scenarios, which are retired rather than retained under misleading headings.
**Migration**: Use `Declared native fleet access policy`, preserving the complete rendered-policy, reachability, negative-fixture, protected-main and deployment authorization contract for the native fleet.

### Requirement: Tailnet SSH access to the Darwin host

**Reason**: Its Linux daemon-builder and Linux-user scenarios no longer describe a supported client after Korolev becomes Windows-only.
**Migration**: Use `Native user SSH access to the Darwin host`, retaining native user authentication, server identity, tailnet-only listening, strict authorization-file ownership, revocation and command-status behavior while rejecting the retired builder key.
