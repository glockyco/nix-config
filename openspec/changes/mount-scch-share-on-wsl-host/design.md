## Context

`/etc/wsl.conf` sets `automount.mountFsTab=false`. WSL itself therefore ignores `/etc/fstab`, and systemd's fstab generator is the only consumer of `fileSystems` entries. WSL provides a `drvfs` mount helper (`/sbin/mount.drvfs`, which links to `/init`). It reaches Windows paths over 9p through the Windows file system, so access uses the Windows session's network credentials. Windows reports `S:` as the DFS path `\\scch.at\SCCH`.

The following spikes ran on Korolev on 7 October 2026 under NixOS-WSL with systemd 260.4:

| Probe                                                           | Result                                                                                                                                                                     |
| --------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `mount -t drvfs '\\scch.at\SCCH' /mnt/s -o ro,uid=1000,gid=100` | Mounted in about 1 s. Listing the full run directory took under 1 s.                                                                                                       |
| Reading a 129 MB file twice                                     | 12.8 MB/s on the first read, 158 MB/s from cache on the second                                                                                                             |
| `mount -t drvfs 'S:' …`                                         | Also works, but depends on the per-user drive mapping                                                                                                                      |
| `wslpath -u 'S:\…'` with the UNC mount active                   | Resolves to `/mnt/s/…`. `wslpath -w /mnt/s/…` returns the UNC path.                                                                                                        |
| Unresolvable host and unreachable address                       | `mount` fails with `Host is down` after 0 s and 22 s                                                                                                                       |
| `systemd-mount` with a backslash source                         | Rejected: `Failed to chase path`                                                                                                                                           |
| fstab line through the real `systemd-fstab-generator`           | Produces `mnt-s.mount` with `What=\\scch.at\SCCH` and an automount that mounts on first access in about 1 s                                                                |
| Generated automount, unreachable source, default start limit    | The first two accesses fail with `ENODEV`. The automount then enters `failed/mount-start-limit-hit`, and later accesses return an empty directory with exit status 0.      |
| The same with `StartLimitIntervalSec=0` on the mount unit       | Every access fails, and the automount stays `active`                                                                                                                       |
| The generated fstab line with fsck pass 2, and with pass 0      | With pass 2, the generator warns `Checking was requested for "\\scch.at\SCCH", but it is not a device.` on every run. Pass 0 generates the same units without the warning. |

## Goals / Non-Goals

**Goals:** The design satisfies the spec. In particular, an unreachable share must fail loudly on every access and never look like an empty share.

**Non-Goals:** Access from outside the corporate network or VPN. Shares other than `\\scch.at\SCCH`. Write access. Notifications when files on the share change.

## Decisions

### Mount the UNC path through `fileSystems` with an automount

`fileSystems."/mnt/s"` uses `device = ''\\scch.at\SCCH''`, `fsType = "drvfs"`, and the options `ro`, `uid`, `gid`, `noauto`, `x-systemd.automount`, and `nofail`. The fstab generator turns this into the same units that the spike proved. NixOS also creates the mount point. `noCheck = true` sets the fsck pass to 0, because the source is no block device and pass 2 makes the generator warn on every run.

Alternatives considered:

- **Drive letter `S:` as the source.** It depends on the drive mapping of the signed-in Windows user, which Windows can change or drop independently of this configuration.
- **A boot-time mount.** It would fail whenever the share is unreachable at start, for example off VPN.
- **Linux CIFS or Kerberos.** It would need credentials or tickets in the Linux user scope. The share is authenticated through the Windows session.
- **NFS straight to the cluster export.** It bypasses the DFS path that users see as `S:`, and it would need a separate network-access decision.

### Take uid and gid from the declared user

The uid and gid come from the evaluated `users.users.<name>` and `users.groups` values, not from literals. The files then belong to the interactive user without embedding a user name or number in the module.

### Disable the mount unit's start limit

Without this, the automount gives up after two failed mount attempts and then serves the empty mount point as success, as the spike showed. A full `systemd.mounts` definition would compete with the fstab-generated unit of the same name, so only a drop-in sets the limit. `systemd.units."mnt-s.mount"` uses `overrideStrategy = "asDropin"` and the text `[Unit]` with `StartLimitIntervalSec=0`. The evaluated Korolev configuration builds a drop-in that holds only those two lines, and it writes the fstab line `\\scch.at\SCCH /mnt/s drvfs ro,uid=1000,gid=100,noauto,x-systemd.automount,nofail 0 0`. The generator therefore still defines the unit itself. With the start limit disabled, an access while the share is down costs one failed mount attempt. The spike measured up to 22 s for an unreachable address and 0 s for an unresolvable name.

### Keep the mount in the host directory

The share belongs to the employer environment of this machine, not to the reusable WSL role. `hosts/korolev/` therefore owns the declaration, following the README's role boundary.

## Risks / Trade-offs

- [The first access per mount is slow over the network, at about 13 MB/s.] → Large inputs are copied to local disk once for repeated analysis. Windows caching makes rereads fast.
- [An access while the share is unreachable can block for up to about 22 s.] → The failure is explicit. Tools that poll `/mnt/s` should not run in that state.
- \[`drvfs` UNC sources are a WSL behavior, not a Linux standard.\] → The evaluation check asserts the declared source and options, and live acceptance repeats the spike probes after each WSL update that changes `/init`.

## Migration Plan

The spike left transient copies of `mnt-s.mount`, `mnt-s.automount`, and the drop-in in `/run/systemd/system`. That directory precedes the generator output in the unit search path (`systemd-analyze unit-paths`). Before activation, stop both units, remove the copies, and reload systemd: `sudo systemctl stop mnt-s.automount mnt-s.mount`, `sudo rm -r /run/systemd/system/mnt-s.*`, and `sudo systemctl daemon-reload`. A WSL restart removes them as well. Then activate the reviewed configuration with `sudo nixos-rebuild switch --flake .#korolev`. Rollback with `sudo nixos-rebuild switch --rollback --no-reexec` removes the units, after stopping them in the same way.
