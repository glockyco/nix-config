## MODIFIED Requirements

### Requirement: Default wrapped command

The default `omp` command SHALL invoke the selected source generation with the immutable personal plugin, curated language tools, and pinned Plannotator executable. Both supported hosts SHALL use the same home-relative selection convention. The wrapper SHALL preserve the caller's working directory and arguments. It SHALL reject the leading executable-update subcommand with instructions to use `omp-dev-update` and SHALL NOT install an official release or invoke a fallback. Plannotator SHALL resolve from the declared package before user-provided alternatives, without changing the parent shell's environment.

#### Scenario: Resolve the default command

- **WHEN** a user resolves `omp` from a fresh login shell on a supported host
- **THEN** the resolved executable is the Nix-managed workstation wrapper
- **AND** the wrapper invokes the selected verified source generation
- **AND** OMP discovers the packaged personal extensions, skills, rule, and LSP overrides
- **AND** annotation commands resolve the unmodified vendor Plannotator executable from the declared commit-pinned input

#### Scenario: Start OMP from Windows Zed

- **WHEN** Windows Zed starts its configured OMP agent server for a NixOS/WSL workspace
- **THEN** Zed's native WSL remote server invokes the wrapped `omp acp` command with an absolute Linux working directory
- **AND** no explicit local `wsl.exe` bridge, native Windows OMP executable, or compatibility path is required

#### Scenario: Reject an upstream executable update

- **WHEN** the user runs `omp update`
- **THEN** the wrapper exits unsuccessfully with the `omp-dev-update` instruction
- **AND** neither the active source generation nor an official executable is modified

#### Scenario: Preserve normal command resolution

- **WHEN** the user starts a normal session or passes `update` outside the leading subcommand
- **THEN** the wrapper preserves the arguments and enables the immutable plugin, language tools, and Plannotator
- **AND** nested `omp` commands continue to resolve to the Nix wrapper
- **AND** the caller's shell environment is unchanged

### Requirement: WSL host network isolation

The WSL host SHALL expose no network service reachable from another host and SHALL remain unreachable from every other tailnet node by policy and by its own shields-up setting. Temporary annotation servers SHALL bind only to loopback and SHALL be reachable by the local Windows browser through WSL local connectivity. They SHALL NOT publish through Tailscale or require firewall openings. The host SHALL hold its tailnet device identity and one root-owned SSH client key dedicated to the Darwin builder. The private key SHALL remain outside the repository and Nix store. Its existing client access to the Darwin host for remote builds and SSH SHALL remain available. No other host SHALL drive it.

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

#### Scenario: Open and end a local annotation review

- **WHEN** a local OMP session on WSL opens a visual annotation review
- **THEN** only a temporary loopback listener is created
- **AND** the local Windows browser can reach it without tailnet publication or a firewall change
- **AND** a terminal result, explicit cancellation, session navigation, or shutdown removes the owned listener
- **AND** tab closure alone can leave the review pending until `/plannotator-cancel` or another cancellation event
