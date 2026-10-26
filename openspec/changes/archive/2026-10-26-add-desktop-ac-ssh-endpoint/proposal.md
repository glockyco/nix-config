# Proposal

## Why

The second personal desktop, `desktop-ac`, is on the tailnet but has no declared SSH endpoint. Running commands on it or tunnelling its Tern web client needs a pinned, key-only path from the Mac, as `desktop` and Korolev have.

## What Changes

- Declare the Mac's `desktop-ac` and `desktop-ac-batch` SSH endpoints with the machine's pinned ED25519 host key, the `hho_h` account and the same transport policy as the other Windows endpoints.
- Extend the endpoint configuration check to the new endpoint.
- Document the hand-configured in-box OpenSSH server, its authorization file, firewall scope and default shell, and the Tern web tunnel, because Tern on Windows cannot host remote sessions.
- List the endpoint in the README.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `fleet-tailnet`: adds the second personal desktop's SSH boundary.

## Impact

`home/.chezmoidata/ssh.toml`, `home/private_dot_ssh/`, `home/.chezmoiignore`, `checks/chezmoi-ssh-check.py`, `flake-modules/checks.nix`, `README.md` and `docs/operations/desktop-ac.md`. The Mac's chezmoi apply writes the new SSH config blocks and the pin file. The machine's own SSH server remains hand-configured.
