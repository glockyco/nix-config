# Proposal

## Why

Colima 0.10 reads a profile without `rootDisk` as a root disk of 0 GiB. The rendered profile omits it, so starting the existing virtual machine tries to shrink its 20 GiB root disk and fails with "disk shrinking is not supported". A local fix added `rootDisk` to the shared host facts and the template, but the typed host declaration rejects the unknown field, so the Mac's system no longer evaluates.

## What Changes

- Add a required positive `rootDisk` in GiB to `host.darwin.containerProfile`, next to `disk`.
- Declare the Mac's `rootDisk` at the size its virtual machine was created with, and render it in the Colima profile.
- Check that the rendered profile carries the declared root disk.
- Note in the container runtime guide that the root disk keeps its size unless the profile is recreated.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `container-runtime`: the host facts also own the root disk size, and the rendered profile carries it.

## Impact

Targets `modules/fleet/host.nix`, `home/.chezmoidata/hosts.toml`, `home/dot_config/colima/default/colima.yaml.tmpl`, `checks/chezmoi-container-check.py` and `docs/operations/container-runtime.md`. The Mac needs a `darwin-switch` with the owner's password. The virtual machine and its data stay as they are.
