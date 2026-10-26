# Design

## Context

Policy membership comes from `modules/shared/tailnet-peers.nix`, rendered by `lib/tailnet-policy.nix`. The single grant gives every node `ip = ["*"]` to each declared tag, so Tern's QUIC remoting on UDP 8376 needs no extra rule. Tag owners are `autogroup:admin`. A node can only advertise a tag that the applied policy already owns, so enrollment has to wait until the `tailnet-policy` workflow has applied the merged change.

## Goals / Non-Goals

**Goals:** make the machine a reachable tagged member and document how it is enrolled by hand.

**Non-Goals:** SSH server, client endpoints or keys, RDP or SMB scoping, the workstation engine, chezmoi, and OMP or Tern setup. The machine is managed by hand.

## Decisions

- Declare it as a peer rather than a managed host. It has no Nix or engine configuration, which is the case the peer data exists for. A host entry would require a host module it doesn't have.
- Name and tag it `desktop-ac` and `tag:desktop-ac`. Its MagicDNS name differs from its Windows computer name, as `desktop` does from DESKTOP-DBHLRDD. Reusing `tag:desktop` would merge two machines' identities in the policy and its tests.
- Make it durable, because it is a long-lived personal machine.
- Install with winget `Tailscale.Tailscale` in machine scope. That is the package the workstation engine uses on Korolev, but here it is run by hand. Enroll from the signed-in standard user with `--unattended=true`, because Tailscale's local API rejects the Administrator account. Unattended mode keeps the node up before sign-in.
- Disable key expiry in the Tailscale console, as for `desktop`. The repository can't express it, so the guide checks `KeyExpiry` instead.

## Risks / Trade-offs

- [Enrolling before the policy is applied fails to advertise the tag] → The guide orders the steps: merge, wait for the apply, then enroll.
- \[Tailscale's `Tailscale-In` firewall rules let every tailnet peer reach every listening port on the machine\] → That is the same posture as `desktop`, and the guide records it. Membership grants no account access.

## Migration Plan

Merge, wait for the `tailnet-policy` apply, enroll the machine, then verify from the Mac. To roll back, remove the device in the Tailscale console and then revert the peer entry.
