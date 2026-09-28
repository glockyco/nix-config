# Evidence

Both hosts were activated from `da6e51d` (merged through PR #45) on 2026-09-28.

## Activation

- Korolev: `sudo nixos-rebuild switch --flake .#korolev` finished with no failed units. `nixos-version --configuration-revision` reported `da6e51d64a663cfb8fbc4e7c34d96accddaf6ac1`.
- Mac: `darwin-switch` ran from the synced checkout at `da6e51d`, and the owner entered the administrator password at the Mac. The closure diff added `macbook-pro-tailnet-authorized-keys` and removed `macbook-pro-builder-authorized-keys`. There was no other package change.
- The rendered authorization file contains `restrict … korolev-builder` and an unrestricted `… korolev` line.

## Client resolution on Korolev

| Command                        | `user`     | `identityfile`                   |
| ------------------------------ | ---------- | -------------------------------- |
| `ssh -G macbook-pro` as `user` | `glockyco` | `/home/user/.ssh/id_ed25519`     |
| `sudo ssh -G macbook-pro`      | `glockyco` | `/root/.ssh/macbook-pro-builder` |

`nix build .#checks.x86_64-linux.korolev-builder-ssh-configuration` passed. A mutation that removed `!localuser root` from the user block made the check fail, because root then resolved two identities.

## Live acceptance as `user`, without sudo

- `ssh -tt macbook-pro 'tty; whoami'` printed `/dev/ttys017` and `glockyco`.
- `ssh macbook-pro-batch 'exit 23' </dev/null` returned status 23.
- A local forward through `macbook-pro-batch` bound its listener. A connection to the listener got `channel 2: open failed: administratively prohibited: open failed`.
- `sudo tailnet-builder-check` reported `tailnet-builder-check: passed` for builder `macbook-pro`.
