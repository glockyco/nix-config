## Why

Tailscale enrollment makes the desktop reachable, but does not provide authenticated remote work or persistent native Windows agents. The owner needs commands, files, and graphical access from the Pro, Air, and Korolev without introducing WSL on the desktop.

## What Changes

- Establish native Windows OpenSSH with PowerShell, per-source public keys, verified host identity, and convenient client connections to `desktop`.
- Install and verify native OMP with a pinned personal plugin source release and the native tools its workflows require. Keep credentials and agent state local to Windows.
- Prove `psmux` terminal persistence with a real agent task, an abrupt SSH disconnect, and reattachment from another machine before accepting it.
- Verify existing RDP access, retained disconnected sessions, and authenticated SFTP. Provide selected SMB folder access without exposing whole disks.
- Restrict desktop remote services to tailnet access. Preserve Korolev's no-inbound boundary and the existing Mac builder credential and endpoint.
- Add a concise desktop-only setup, verification, and recovery procedure using supported platform tools. Keep the employer Windows configuration and Nix activation unchanged.

## Capabilities

### New Capabilities

- `native-windows-remote-work`: authenticated desktop access, native agent dependencies, persistent terminal sessions, graphical and file access, and bounded provisioning/recovery.

### Modified Capabilities

None. The existing work-machine Windows document and fleet network authorization remain unchanged. This capability adds application-level access to the already declared desktop destination.

## Non-goals

WSL or Linux on the desktop; gaming; exact-console screen mirroring; GUI automation while locked; hosted OMP collab; a custom session broker; automatic agent restart after reboot; file synchronization or backup. General incoming access to the Macs is separate work. This change configures them only as desktop clients and preserves the temporary Air's removal boundary.

## Impact

The personal Windows desktop gains native tools and explicitly approved service settings. Client SSH entries may change in the existing platform modules. The personal plugin repository remains the owner of plugin code; any Windows compatibility fix requires a separate change there before its pin advances here.

The desktop remains an unmanaged Windows peer, not a NixOS host. Supported Windows tools and a focused operating procedure own its manual setup; this change adds no competing Windows configuration generator. Existing `modules/windows/` artifacts target the work machine and must not be applied to the personal desktop as a shortcut.

Implementation requires authenticated local or RDP access and local administrator approval for service changes. Planning and read-only probes do not authorize installation or acceptance. The existing `connect-fleet-over-tailnet` change retains its own unchecked gates.
