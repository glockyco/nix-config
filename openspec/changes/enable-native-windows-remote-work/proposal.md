## Why

Tailscale enrollment makes the desktop reachable, but does not provide authenticated remote work or persistent native Windows agents. The owner needs commands, files, and graphical access from the Pro, Air, and Korolev.

The desktop already runs WSL 2 with an Ubuntu distribution and Docker Desktop's distributions, and the owner has since decided that a NixOS-WSL host on the desktop is wanted, mirroring Korolev. The original exclusion of WSL was therefore an assumption about the machine rather than a requirement, and this revision withdraws it. The Windows access layer below stays native and is not built on WSL; the agent surface becomes an explicit open decision instead of a settled one.

## What Changes

- Repair the native release-gate defects discovered during client verification: the dependency audit pipeline crash, documentation declaration paths that lose store context, and contention from concurrent Nix evaluations. Preserve auditing, documentation, caching, and the existing package-set ownership.
- Establish native Windows OpenSSH with PowerShell, per-source public keys, verified host identity, and convenient client connections to `desktop`. The desktop's SSH account is the owner's existing local administrator account, not a new standard user.
- Install and verify native OMP with a pinned personal plugin source release and the native tools its workflows require. Keep credentials and agent state local to Windows.
- Add no multiplexer and no live-persistence capability. The desktop is driven for agentic work through non-interactive SSH commands, so an agent may end with its connection and saved conversation state is resumed explicitly. `psmux` was installed during investigation and removed again.
- Verify existing RDP access, retained disconnected sessions, and authenticated SFTP. Keep file access authenticated and inspected; whole-volume reach follows from administrator membership rather than from a new share.
- Restrict desktop remote services to tailnet access. Preserve Korolev's no-inbound boundary and the existing Mac builder credential and endpoint.
- Add a concise desktop-only setup, verification, and recovery procedure using supported platform tools. Keep the employer Windows configuration and Nix activation unchanged.
- Permit WSL on the desktop and record the intended NixOS-WSL host as follow-on work, without making this change's Windows access gates depend on it. Declaring a second `x86_64-linux` host requires the deferred `key-fleet-by-host` change first, because the flake's host table is keyed by system.

## Capabilities

### New Capabilities

- `native-windows-remote-work`: authenticated desktop access, native agent dependencies, persistent terminal sessions, graphical and file access, and bounded provisioning/recovery.

### Modified Capabilities

- `batch-ssh`: the named non-interactive endpoint contract is currently written for the MacBook Air alone. The desktop needs the same split between terminal-capable and unattended connections, so the requirement becomes host-neutral and covers both destinations.

The existing work-machine Windows document and fleet network authorization remain unchanged. This capability adds application-level access to the already declared desktop destination.

## Non-goals

Gaming; exact-console screen mirroring; GUI automation while locked; hosted OMP collab; a custom session broker; automatic agent restart after reboot; file synchronization or backup. General incoming access to the Macs is separate work. This change configures them only as desktop clients and preserves the temporary Air's removal boundary.

Also excluded: installing or configuring the NixOS-WSL host itself, scheduling `key-fleet-by-host`, and removing the desktop's existing ZeroTier, TeamViewer, or Chrome Remote Desktop installations. Those remote-access paths are credential-gated rather than firewall-gated, and this change records them instead of dismantling working owner tooling.

## Impact

The personal Windows desktop gains native tools and explicitly approved service settings. Client SSH entries may change in the existing platform modules. The personal plugin repository remains the owner of plugin code; any Windows compatibility fix requires a separate change there before its pin advances here.

The desktop remains an unmanaged Windows peer for the purposes of this change: no Nix activation applies Windows settings, and no competing Windows configuration generator appears. Existing `modules/windows/` artifacts target the work machine and must not be applied to the personal desktop as a shortcut. A future NixOS-WSL host on this machine is managed as its own NixOS configuration and does not change that boundary for the Windows layer.

Implementation requires authenticated local or RDP access and local administrator approval for service changes. Planning and read-only probes do not authorize installation or acceptance. The existing `connect-fleet-over-tailnet` change retains its own unchecked gates.
