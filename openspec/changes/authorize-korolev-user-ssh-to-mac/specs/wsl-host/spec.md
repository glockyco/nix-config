## MODIFIED Requirements

### Requirement: WSL host network isolation

The WSL host SHALL expose no network service reachable from another host and SHALL remain unreachable from every other tailnet node by policy and by its own shields-up setting. Temporary annotation servers SHALL bind only to loopback and SHALL be reachable by the local Windows browser through WSL local connectivity. They SHALL NOT publish through Tailscale or require firewall openings. The host SHALL hold its tailnet device identity, one root-owned SSH client key dedicated to the Darwin builder, and its interactive user's own SSH client key. Private keys SHALL remain outside the repository and Nix store. Root SHALL resolve the Darwin host to the builder key, and the interactive user SHALL resolve it to the user key. Its client access to the Darwin host for remote builds and SSH SHALL remain available. No other host SHALL drive it.

#### Scenario: Inspect the running host

- **WHEN** the WSL host is running
- **THEN** it runs no SSH server, no tailnet SSH server, and no other externally reachable inbound service
- **AND** its firewall declares no open TCP or UDP port
- **AND** the configuration declares no secret and no age recipient for this host

#### Scenario: Another node attempts to reach the WSL host

- **WHEN** the Darwin host, the Air, or the desktop attempts a tailnet connection to the WSL host
- **THEN** the connection is refused
- **AND** the tailnet policy tests assert that refusal at every policy apply

#### Scenario: The WSL host reaches the Darwin host

- **WHEN** the WSL host opens a remote build session to the Darwin host
- **THEN** tailnet policy permits the network connection and OpenSSH authenticates the dedicated builder key
- **AND** the client key is readable only by root, and only its public key and private-key path enter the configuration

#### Scenario: The WSL user opens a shell on the Darwin host

- **WHEN** the WSL host's interactive user runs `ssh macbook-pro`
- **THEN** the client offers only the user's own key and verifies the declared Darwin host key
- **AND** it never selects the root-owned builder key

#### Scenario: Open and end a local annotation review

- **WHEN** a local OMP session on WSL opens a visual annotation review
- **THEN** only a temporary loopback listener is created
- **AND** the local Windows browser can reach it without tailnet publication or a firewall change
- **AND** a terminal result, explicit cancellation, session navigation, or shutdown removes the owned listener
- **AND** tab closure alone can leave the review pending until `/plannotator-cancel` or another cancellation event
