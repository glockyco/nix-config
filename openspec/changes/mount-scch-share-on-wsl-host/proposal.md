## Why

Research data on the SCCH share, including the cluster's run outputs, is mapped on Windows as `S:` (`\\scch.at\SCCH`). Korolev has no Linux path to it, because WSL automounts only fixed local drives. Every analysis of a run therefore starts with a manual mount or a copy through Windows.

## What Changes

- On first access, mount `\\scch.at\SCCH` read-only at `/mnt/s` through WSL's Windows file bridge. The signed-in Windows session authenticates the mount.
- Keep the automount armed when the share is unreachable. Each access then fails with an error until the share is reachable again, rather than leaving an empty directory.
- Assert the mount and automount units in Korolev's evaluation checks.
- Document the path in the README.
- Do not store credentials, add Linux SMB or Kerberos tooling, or mount the cluster's NFS export directly.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `wsl-host`: The host provides read-only, on-demand access to the SCCH share at `/mnt/s`.

## Impact

`hosts/korolev/`, the Korolev checks in `flake-modules/checks.nix`, and the README's network section. Activation adds one mount unit and one automount unit. It mounts nothing until first access and starts no service. Writes to the share stay with Windows.
