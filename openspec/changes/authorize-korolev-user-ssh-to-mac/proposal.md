## Why

Korolev's interactive user cannot open a shell on the MacBook Pro. The Mac's tailnet SSH daemon authorizes only the root-owned `korolev-builder` key, and that key denies PTY allocation. Mac-side operations such as a configuration pull, `darwin-switch`, and `omp-dev-update` therefore need a person at the Mac, or they need the build credential used as a general shell, which the builder boundary forbids.

## What Changes

- Authorize Korolev's user-owned key (`korolev`) as a second, labeled entry in the Mac's declared tailnet authorization file. Unlike the builder key, it may allocate a terminal. Forwarding and tunnels stay disabled for every key.
- On Korolev, resolve `macbook-pro` for the interactive user to the Mac's declared user and that user key. Add a `macbook-pro-batch` counterpart for unattended commands. Root, and therefore the Nix daemon, keeps resolving `macbook-pro` to the dedicated builder key and its unchanged transport.
- Add a daemon-free Korolev check that proves both endpoint resolutions, including the root builder resolution, and the batch transport settings.
- Document the Mac endpoints beside the desktop endpoints.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `fleet-tailnet`: the Darwin host authorizes a second, user-owned key from the Linux host for interactive and batch commands. The builder key keeps its restrictions.
- `wsl-host`: the WSL host holds a user-owned client key for the Darwin host besides the root-owned builder key.
- `batch-ssh`: the Mac gains a batch endpoint paired with its interactive endpoint.

## Impact

Affected files are `modules/roles/darwin/desktop/tailscale.nix`, `modules/roles/nixos/wsl-workstation/programs.nix`, `flake-modules/checks.nix`, a new Korolev SSH configuration check, and README network guidance. No new daemon, listener, port, or tailnet policy rule is added. Korolev keeps its no-inbound boundary. The Mac must activate the change before the key authenticates. Removing the entry and reactivating revokes the key without touching remote builds.
