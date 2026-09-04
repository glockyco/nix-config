## MODIFIED Requirements

### Requirement: WSL host network isolation

The WSL host SHALL expose no listening network service and SHALL be unreachable from every other tailnet node by policy and by its own shields-up setting. It SHALL hold its tailnet device identity and no other key or shared secret. It MAY act as a client of the Darwin host for remote builds and SSH. No other host SHALL drive it.

#### Scenario: Inspect the running host

- **WHEN** the WSL host is running
- **THEN** it runs no SSH server, no tailnet SSH server, and no other inbound service
- **AND** its firewall declares no open TCP or UDP port
- **AND** the configuration declares no secret and no age recipient for this host

#### Scenario: Another node attempts to reach the WSL host

- **WHEN** the Darwin host, the Air, or the desktop attempts a tailnet connection to the WSL host
- **THEN** the connection is refused
- **AND** the tailnet policy tests assert that refusal at every policy apply

#### Scenario: The WSL host reaches the Darwin host

- **WHEN** the WSL host opens a remote build session to the Darwin host
- **THEN** the session is authenticated by tailnet identity and no private key file exists on the WSL host
