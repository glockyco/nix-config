## Current scope: 2026-09-05

Preserve the deployed Korolev–Mac configuration and its verified SSH/build path. OMP usability and C# acceptance are separate; neither blocks network verification.

Task 5.2 is complete: the coordinated WSL restart preserved resolver ownership, public DNS, MagicDNS, tailnet connectivity, and installed SSH access. The owner does not use employer-internal DNS from WSL, so that check is not applicable. Do not schedule another restart. Task 4.6 also passed: the live LAN and Korolev inbound SSH probes timed out, while the Mac tailnet SSH control succeeded. Preserve the existing no-inbound and tailnet-only boundaries. Only deferred optional tasks remain.

Tasks 6.5, 7.1, 7.3, and 7.4 are deferred optional work: disconnected-builder recovery and Air/desktop enrollment and access. Preserve their unchecked status and technical acceptance contracts. They do not block basic OMP use or the already verified Korolev–Mac connection. Schedule them only when needed and with the owner's coordination. Air offboarding before return remains required, regardless of this scheduling decision.

This change is incomplete and must not be archived as accepted while its gates remain open. CLI task counts do not authorize deferred work. Do not redesign working networking, SSH, policy deployment, or remote building to close the near-term checks.

## Why

Cross-platform verification needs a private, addressable path from the WSL host `korolev` to the Mac's native Nix daemon. WSL's NAT resolver did not resolve the Mac's mDNS name, and the Mac had Remote Login disabled. A tailnet and Nix's native `ssh-ng` builder remove the need to move manually between machines.

The owner accepted a tailnet device identity and outbound remote builds on `korolev`, reversing the earlier no-other-host-control decision while retaining its no-inbound boundary. The employer endpoint-monitoring concern is recorded and accepted.

The initial Tailscale SSH implementation loses nonzero remote exit status on this Mac. Native SSH returned success for `exit 23`. On 2026-09-05, the owner approved standard OpenSSH over Tailscale with a dedicated root-owned client credential instead of an exit-status workaround. This also reverses the original no-private-key constraint. A failed remote gate must remain a failed gate.

The Air is borrowed temporarily for PhD thesis and TOSEM research-result retrieval. It is not a durable builder, storage authority, authentication dependency, or release dependency.

## What Changes

- Join the durable managed hosts, durable desktop peer, and temporary Air peer to one tagged tailnet. MagicDNS names replace mDNS and LAN addressing. Peer data records lifecycle and purpose.
- Render policy from Nix data. Grants permit access to reachable destinations and never to `korolev`. Renderer assertions and provider network tests defend that boundary. Remove Tailscale SSH authorization when OpenSSH owns authentication.
- Validate PR policy with a read-only federated identity. Deploy only after successful native checks for a main revision, from that exact revision, through a separate main/workflow-constrained write identity. Serialize writes and reject obsolete deployment revisions.
- Require PRs and the native Linux, Darwin, and policy checks on main; enforce linear history and protect against force-push and deletion. The single owner still performs the human review.
- Run native OpenSSH as a nix-darwin launchd daemon bound to the Mac's full MagicDNS name. Disable Tailscale SSH and Apple's wildcard socket-activated Remote Login service. Do not add a network proxy, LAN listener, or exit-status parser.
- Keep one root-owned builder private key on `korolev`, outside the repository and Nix store. Declare its restricted public authorization on the Mac and pin the Mac's actual OpenSSH public host key. Remove the obsolete Tailscale `KnownHostsCommand` implementation and callers.
- Declare one `ssh-ng` Darwin builder from the Mac's host declaration. Keep its user in `trusted-users` because remote builds import unsigned paths. The credential permits remote build and verification commands; it is not a command sandbox.
- Preserve `korolev` isolation: no inbound service, shields-up, no Taildrop, and no open firewall port. Manage WSL DNS through resolved, with the Windows DNS-tunneling upstream preserved across a real restart.
- Point the Air's SSH and SMB clients at `macbook-air`. Keep the existing Secure Enclave authentication and batch transport. Prove activated online/offline behavior after enrollment.
- Track Air offboarding outside this active change: preserve results, revoke the node before return, and remove its declaration, policy, endpoints, credentials, and role.
- Prove live remote builds, native command failure propagation, key rejection, tailnet-only listening, disconnected-builder failure/recovery, and native release gates. Keep deployment gates open until exercised after review and merge.

## Capabilities

### New Capabilities

- `fleet-tailnet`: durable and temporary member identity, declared reachability policy, OpenSSH authentication over the tailnet, and the Darwin remote builder.

### Modified Capabilities

- `personal-omp-workstation`: permit a tailnet identity and dedicated root-owned builder key on WSL while retaining the no-inbound boundary.
- `repository-quality-gates`: build Darwin checks from Linux and preserve native exit status for remote Darwin inspection commands.

## Impact

The change affects host declarations, the policy renderer and workflow, Darwin Tailscale/OpenSSH configuration, Linux resolver/SSH/builder configuration, the Air clients, their behavioral checks, and operating procedures. Both managed system derivations change. Private keys and enrollment state remain mutable local state, not Nix inputs.

Mac activation occurs only after review and merge, from a local administrator session with the previous generation retained. WSL restart, peer enrollment, provider trust verification, actual GitHub events, and root-daemon acceptance are distinct gates; configuration evaluation cannot substitute for them.

The change follows the archived `declare-typed-host-options` change. It adds no general fleet framework and does not manage the Air's or desktop's operating system.
