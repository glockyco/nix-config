## Context

The Mac's `tailnet-sshd` reads `/var/lib/tailnet-sshd/authorized_keys/glockyco`. Activation installs that file from one Nix-store text containing only `restrict … korolev-builder`. On Korolev, the system SSH configuration maps `Host macbook-pro` to the builder user and the root-only key `/root/.ssh/macbook-pro-builder`. Because that block applies to every local user, `ssh macbook-pro` as `user` selects an unreadable key and fails. Korolev's user key `~/.ssh/id_ed25519` (comment `korolev`) already authenticates to the desktop.

## Goals / Non-Goals

**Goals:**

- Let Korolev's user open interactive and batch sessions on the Mac with a user-owned key.
- Keep the Nix daemon's builder resolution byte-for-byte equivalent in effective settings.

**Non-Goals:**

- Restrict the user key to a command set. The purpose is general administration, including `sudo darwin-switch`.
- Change tailnet policy. Korolev may already reach the Mac.
- Give any host access to Korolev.

## Decisions

### Split one host alias by local user

`Match originalhost macbook-pro localuser root` gives root the builder user, key, and transport. The user endpoints use `Match originalhost … !localuser root` instead of `Host`. OpenSSH accumulates `IdentityFile` values across matching blocks, so block order alone would still offer root the user key as a fallback. Every other user receives only the interactive user key. The build machine URI stays `macbook-pro`, which the isolation check and `nix.buildMachines` rely on.

Alternative: a separate alias such as `mac-shell`. It leaves `ssh macbook-pro` broken for the user, the name the owner expects to use.

Alternative: rename the builder to `macbook-pro-builder`. That changes the store URI, the isolation check, and the remote-builder contract for no user benefit.

### Reuse the existing user key with its own authorization line

`~/.ssh/id_ed25519` is already Korolev's user-owned credential for the desktop. A labeled line on the Mac can be removed independently of the builder line. A second key per destination would add enrollment work without separating any trust that the Mac line does not already separate.

### Per-key options, shared daemon restrictions

The builder line keeps `restrict`. The user line has no `restrict`, because it needs a PTY. `DisableForwarding yes` and `PermitTunnel no` remain daemon-wide, so neither key can forward.

### Check both branches without root

The check renders the effective system `ssh_config` with `ssh -G` as the build user and asserts the user resolution. It then substitutes `localuser root` with the build user's name in a copy and asserts the builder resolution. This proves the ordering without running as root.

## Risks / Trade-offs

- \[A later `Host *` block could override values for root\] → The check asserts root's effective user, key, known-hosts file, and batch mode.
- [The user key gains broad Mac access] → The key is readable only by `user`, the Mac still requires its administrator password for `sudo`, and one line removal revokes it.
- [Activation order] → The Mac must activate the new authorization file before the user key authenticates. Until then, the builder key keeps working.

## Migration Plan

1. Merge the change. Activate Korolev, then the Mac.
1. Verify `ssh macbook-pro true`, the batch endpoint's exit-status propagation, and `nix build` of a Darwin derivation through the builder.

Rollback: revert the change and activate both hosts. The builder line is unchanged throughout.
