## MODIFIED Requirements

### Requirement: Authenticated terminal access from each source

The Pro, Air and native Windows Korolev SHALL reach `desktop` with native OpenSSH, independently approved credentials and a pinned server identity. The Pro and desktop SHALL likewise reach Windows Korolev with separate source keys. Commands SHALL preserve native Windows shell behavior and exit status. Network membership SHALL not grant account access; revoking one source key SHALL not revoke others.

#### Scenario: Use the desktop from each source

- **WHEN** an authorized source connects through its saved desktop SSH entry
- **THEN** it reaches the intended Windows account without address or username guessing
- **AND** a command exiting with status 23 returns status 23 to the client

#### Scenario: Reject an unknown client or server

- **WHEN** a client presents an unauthorized key or the server presents an unexpected host key
- **THEN** the connection fails without password fallback or automatic host-key acceptance

#### Scenario: Remove temporary source access

- **WHEN** the Air's desktop authorization is revoked before its return
- **THEN** the Air can no longer authenticate to the desktop
- **AND** the Pro and Korolev retain their own access

#### Scenario: Reach the standard work account

- **WHEN** the Pro or desktop authenticates to Windows Korolev
- **THEN** it reaches the approved standard account without password or keyboard-interactive fallback
- **AND** a command exiting 23 returns status 23
- **AND** a privileged service operation still requires separate owner-assisted local Administrator approval

### Requirement: Tailnet-only access and existing fleet isolation

Desktop SSH, RDP and SMB SHALL retain effective approved-tailnet restrictions. Native Korolev SSH SHALL be bound/restricted to its tailnet addresses with independently approved keys. The Pro's builder access SHALL remain usable through Windows Tailscale; WSL SHALL retain its no-listener boundary. Loss of Tailscale SHALL not create a permissive fallback. Independent authenticated desktop relay products remain outside this service boundary and SHALL be enumerated with effective firewall scope.

#### Scenario: Compare allowed and denied paths

- **WHEN** an authorized source tests a configured service through Tailscale and through a reachable non-tailnet interface
- **THEN** the tailnet connection succeeds and the non-tailnet connection fails
- **AND** a missing route is not accepted as proof of firewall enforcement

#### Scenario: Work away from home

- **WHEN** a source and the desktop use different physical networks
- **THEN** the saved desktop name supports authenticated terminal, graphical, and file access without router port forwarding

#### Scenario: Preserve the installed fleet

- **WHEN** desktop setup completes
- **THEN** approved Mac and desktop keys reach Windows Korolev over Tailscale, while non-tailnet SSH and WSL inbound services remain blocked
- **AND** the existing Korolev-to-Pro remote build and command-status checks still pass
