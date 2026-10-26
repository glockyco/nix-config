# Spec Delta

## ADDED Requirements

### Requirement: Second personal desktop SSH boundary

The Mac SHALL reach the second personal desktop through declared interactive and batch SSH endpoints that pin its host key and use only public-key authentication with the Mac's own key. The machine SHALL accept SSH only on its tailnet addresses, with password and keyboard-interactive authentication disabled.

#### Scenario: Run a command from the Mac

- **WHEN** the Mac runs `ssh desktop-ac-batch 'exit 23'`
- **THEN** the command runs as the declared account and the client returns status 23

#### Scenario: Deny an unapproved path or credential

- **WHEN** a client offers a password or keyboard-interactive login, or connects to TCP 22 on the machine's LAN address
- **THEN** authentication fails with `Permission denied (publickey)` or the connection is refused
- **AND** a changed host key fails client verification without password fallback
