# Proposal

## Why

A second personal Windows PC, DESKTOP-ARNTPG5, runs Tern and OMP and needs to be reachable from the Mac and the other fleet machines. It is only on the LAN today, and the tailnet policy grants access to declared tags only, so an enrolled but undeclared node would be unreachable.

## What Changes

- Declare `desktop-ac` as a durable tailnet peer with `tag:desktop-ac`. The generated policy then gives it a tag owner, a grant destination and positive network tests.
- Add an operations guide for the machine. It covers installing Tailscale for Windows by hand, enrolling it with its tag, unattended mode and disabled key expiry, and checking that it is reachable.
- List the machine in the README's network section.
- The repository manages nothing else on the machine: no SSH endpoint, keys, workstation engine run or chezmoi state.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `fleet-tailnet`: the declared native fleet access policy names the second personal desktop among its reachable members.

## Impact

- `modules/shared/tailnet-peers.nix` gains one entry. The rendered policy and the `tailnetPolicy` and `tailnetPolicyRejects` checks pick it up from the data.
- After merge, the `tailnet-policy` workflow applies the new policy to Tailscale.
- `docs/operations/` gains a guide for the machine, and `README.md` names it.
- Enrolling and disabling key expiry happen on the machine and in the Tailscale console. The repository cannot express either one.
