## MODIFIED Requirements

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
