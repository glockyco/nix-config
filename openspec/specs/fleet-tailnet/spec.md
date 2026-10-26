# fleet-tailnet Specification

## Purpose

Connects durable fleet hosts and declared temporary peers over one private tailnet, governs their reachability through tested policy, and limits SSH to the declared native accounts and keys.

## Requirements

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

### Requirement: Declared native fleet access policy

Repository-rendered policy SHALL grant every tailnet node access to declared reachable members, including native Windows Korolev, the Mac, desktop, the second personal desktop desktop-ac and temporary Air. It SHALL generate positive port-22 tests and synthetic unreachable-destination rejection tests. It SHALL contain no email addresses or Tailscale SSH authorization. Reviewed separate test/deploy identities and protected-main acceptance SHALL remain effective; no retired host gate SHALL authorize deployment.

#### Scenario: Render the policy

- **WHEN** the repository renders the policy
- **THEN** the output is a valid policy document with one grant set, tag owners for every declared tag, and network tests
- **AND** it contains no Tailscale SSH rules or SSH tests

#### Scenario: Reach the second personal desktop

- **WHEN** desktop-ac is enrolled with tag:desktop-ac and another fleet machine connects to it by its tailnet name
- **THEN** the policy permits the network path
- **AND** membership alone does not authorize any Windows account access

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

### Requirement: Second personal desktop SSH boundary

The Mac SHALL reach the second personal desktop through declared interactive and batch SSH endpoints that pin its host key and use only public-key authentication with the Mac's own key. The machine SHALL accept SSH only on its tailnet addresses, with password and keyboard-interactive authentication disabled.

#### Scenario: Run a command from the Mac

- **WHEN** the Mac runs `ssh desktop-ac-batch 'exit 23'`
- **THEN** the command runs as the declared account and the client returns status 23

#### Scenario: Deny an unapproved path or credential

- **WHEN** a client offers a password or keyboard-interactive login, or connects to TCP 22 on the machine's LAN address
- **THEN** authentication fails with `Permission denied (publickey)` or the connection is refused
- **AND** a changed host key fails client verification without password fallback
