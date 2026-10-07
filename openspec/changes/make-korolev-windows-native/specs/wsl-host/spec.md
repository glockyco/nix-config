## MODIFIED Requirements

### Requirement: WSL host network isolation

The secondary WSL host SHALL expose no externally reachable network service, SSH server, tailnet SSH server or firewall port. Windows SHALL own Korolev's reachable tailnet identity; WSL SHALL route outbound via Windows Tailscale without its own daemon or enrollment. Loopback annotation connectivity SHALL remain local. Root builder and user SSH keys SHALL stay separate, outside the repository/store, with pinned server verification and no root key use by Windows.

#### Scenario: Inspect the running host

- **WHEN** the WSL host is running
- **THEN** it runs no SSH server, no tailnet SSH server, and no other externally reachable inbound service
- **AND** its firewall declares no open TCP or UDP port
- **AND** no Tailscale daemon, Linux node identity, or externally reachable listener is configured; any chezmoi key remains user-owned and is not a system secret

#### Scenario: Another node attempts to reach the WSL host

- **WHEN** the Darwin host, the Air, or the desktop connects to the Windows Korolev address
- **THEN** Windows may accept approved native services, but WSL exposes no SSH/service path
- **AND** no Windows port proxy or WSL service forwarding is added

#### Scenario: The WSL host reaches the Darwin host

- **WHEN** the WSL host opens a remote build session to the Darwin host
- **THEN** Windows Tailscale carries the permitted network connection and OpenSSH authenticates the dedicated builder key
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
