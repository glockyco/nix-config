# Tasks

## 1. Declaration

- [x] 1.1 Add the durable `desktop-ac` peer with `tag:desktop-ac` to `modules/shared/tailnet-peers.nix`. Verify that `nix build .#tailnet-policy` renders a tag owner, a grant destination and a port-22 accept test for `tag:desktop-ac`, and that the `tailnetPolicy` and `tailnetPolicyRejects` checks pass.
- [x] 1.2 Add `docs/operations/desktop-ac.md` covering the manual winget install, standard-user enrollment with `--hostname=desktop-ac --advertise-tags=tag:desktop-ac --unattended=true`, disabled key expiry and its `KeyExpiry` check, and the firewall posture. Name the machine in the README's network section with a link to that guide. Verify that the links resolve and that the README checks pass.

## 2. Delivery

- [x] 2.1 Open a PR, run the README checks for Darwin and the portable checks, and merge after the required checks and the live policy test pass. Verify that the `tailnet-policy` deployment run applies the merged revision.
- [x] 2.2 Ask for the interactive enrollment on DESKTOP-ARNTPG5 by following the guide. Verify from the Mac that `tailscale status --json` lists `desktop-ac` online with exactly `tag:desktop-ac` and an empty key expiry, and that `tailscale ping --until-direct=false desktop-ac` gets a pong.
