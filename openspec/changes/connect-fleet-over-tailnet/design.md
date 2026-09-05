## Context

This change follows the archived `declare-typed-host-options` change. Managed hosts declare `options.host`; user modules read `osConfig.host`.

On 2026-09-04, `korolev` ran WSL 2 in NAT mode with Windows DNS tunneling at `10.255.255.254`. It could not resolve the Mac's mDNS name. Remote Login on the Mac was off. The owner accepted a tailnet device identity on the work machine and outbound remote builds, while retaining its no-inbound boundary. The borrowed Air serves only PhD thesis and TOSEM research-result retrieval.

On 2026-09-05, both managed hosts were enrolled. A native OpenSSH client connecting to the Mac's Tailscale SSH server reported success for `/bin/sh -c 'exit 23'`. The Mac runs Tailscale 1.98.10. Upstream issue [tailscale/tailscale#18256](https://github.com/tailscale/tailscale/issues/18256) describes this macOS failure; its linked fix was closed without merging. An upgrade is not evidence of a correction.

The owner approved OpenSSH over Tailscale instead of an exit-status wrapper. This reverses the no-client-private-key constraint. Remote command status is a release requirement, not optional diagnostic information.

## Goals / Non-Goals

**Goals:**

- Stable tailnet names for durable hosts and declared temporary peers.
- No inbound path to `korolev`; a root-owned, dedicated SSH credential permits outbound builds and non-interactive verification on the Mac.
- Correct SSH exit status, key verification, and no SSH listener on a Mac LAN address.
- Reviewed policy, read-only PR validation, and serialized deployment of a checked main revision.
- Temporary Air removal without a durable dependency.

**Non-goals:** Windows work-host management, subnet routers, exit nodes, Taildrop, Funnel, Serve, and management of the Air or desktop operating systems. Their owners install and authenticate the Tailscale applications. No activation installs OMP or modifies its runtime state.

## Decisions

### 1. Tagged nodes and MagicDNS

Managed hosts declare `host.tailnet.tag` and `host.tailnet.reachable`. `modules/shared/tailnet-peers.nix` declares unmanaged peers with a tag, lifecycle, and non-empty purpose. The desktop is durable; the borrowed Air is temporary. Node names match host names. Configuration uses tailnet names, not LAN addresses or mDNS names.

Tags keep account addresses out of this public policy. Tagged nodes do not expire automatically. Offboarding must revoke the Air node before its return. Each tag is owned by `autogroup:admin`.

### 2. Policy authorization and deployment

`packages/tailnet-policy.nix` renders JSON HuJSON from managed hosts and peer data. Grants permit nodes to reach declared reachable tags; no grant names `korolev`. Network tests deny TCP port 22 to `korolev` from each reachable tag. Renderer assertions reject unreachable destinations, account-address data, and incomplete peer metadata. A fixture without the Air must retain every durable invariant.

OpenSSH owns SSH authentication. Remove Tailscale SSH rules and `sshTests`, rather than retaining unused authorization. Network grants and tests still govern reachability.

GitHub main protection requires pull requests, current `check (macos-15)`, `check (ubuntu-latest)`, and `test` checks from GitHub Actions, linear history, administrator enforcement, and no force-push or deletion. The single owner reviews before merge. Zero required approvals avoids requiring an impossible self-approval; branch protection does not prove independent human review.

`.github/workflows/tailnet-policy.yml` validates pull requests with a separate read-only federated identity. Its scopes are `policy_file:read`, `devices:posture_attributes:read`, and `devices:core:read`. `TS_TEST_OAUTH_ID` and `TS_TEST_AUDIENCE` identify it. Missing credentials fail; validation must not fall back to deployment credentials.

Deployment follows successful completion of the push-triggered `check` workflow on this repository's main branch. It checks out that run's exact `head_sha`, renders the policy, and compares the checked revision with current main immediately before applying it. Obsolete revisions are skipped; API errors fail. Apply jobs use one concurrency group with `cancel-in-progress: false` and `queue: max`. This prevents overlapping writes but does not promise deployment of every intermediate commit or survival of manual cancellation and queue overflow.

Deployment uses `TS_OAUTH_ID` and `TS_AUDIENCE`, with `TS_TAILNET` shared by both jobs. Deployment scopes are `policy_file`, `devices:posture_attributes`, and `devices:core:read`. The provider must constrain this identity to the actual main subject and the `workflow_run`, repository, ref, and workflow claims. PR identity trust is restricted to the actual PR subject, repository, base branch, and event. Inspect the configured subject format; do not assume GitHub's legacy name-only format. Provider restrictions, not an `action: test` input, enforce the read/write separation.

The admin console's prevent-edits setting records this repository as the external policy source. An authorized administrator can override it. It is a break-glass procedure, not an immutable boundary.

### 3. Standard OpenSSH on the Mac's tailnet address

Keep Tailscale's open-source daemon for networking. The existing authenticated-state runner applies `--ssh=false`, disabling the server that loses command status. Keep the upstream `extraSetFlags` follow-up; delete the local option and runner only when upstream supplies equivalent ordering.

Apple's Remote Login launchd service uses socket activation. `ListenAddress` in `sshd_config` does not constrain that service's listening socket. Explicitly disable it with `services.openssh.enable = false`.

A dedicated nix-darwin launchd daemon runs `/usr/sbin/sshd -D -f` with a repository-generated configuration. `ListenAddress` is the Mac's full MagicDNS name, derived from `config.host.name` and `tailnetDnsDomain` in the existing shared data module. The shared domain is `tail8768af.ts.net`; the SSH client uses the same declaration. There is no wildcard or LAN listener. Startup fails when the name or address is unavailable; launchd retries. The daemon uses its declared `AUTH` syslog facility instead of redirecting authentication diagnostics to uncaptured launchd standard error. Do not add an address-discovery wrapper, network proxy, or permissive fallback.

Use the existing `/etc/ssh/ssh_host_ed25519_key`, generated by nix-darwin's OpenSSH host-key activation when absent. Pin its measured public key on the client. The dedicated configuration permits only public-key authentication as the declared user, disables passwords, keyboard-interactive authentication, root login, forwarding, and tunnels, and reads a root-owned declarative authorized-keys file. An `environment.etc` file resolves into the group-writable Nix store and fails OpenSSH's canonical-path strict-mode check. Activation therefore copies the public authorization into `/var/lib/tailnet-sshd/authorized_keys` before launchd reloads the daemon. It does not disable `StrictModes` or weaken Nix store permissions. Use PAM for the native macOS account/session boundary.

The builder key's `restrict` authorization still permits command execution: remote Nix and native release commands both need it. It is not a command sandbox. The remote user remains a Nix trusted user and can import unsigned paths; compromise of this credential has the corresponding Nix trust impact. Additional owner devices require explicit public-key enrollment rather than implicit Tailscale check-mode access.

### 4. Client credentials and host verification

Generate one Ed25519 client key locally as root at `/root/.ssh/macbook-pro-builder`, mode 0600, in a root-only directory. Never import the private key into the Nix store, repository, logs, or activation. Declare its public key on the Mac with `restrict`. Loss or compromise requires replacement of the local key and reviewed replacement of its authorized public key.

`nix.buildMachines.sshKey` names that path. The system SSH alias derives `IdentityFile` from the declared builder, uses `IdentitiesOnly yes`, `StrictHostKeyChecking yes`, `BatchMode yes`, `ConnectTimeout 8`, `ControlMaster no`, and `ControlPath none`. Root performs remote release commands through the same alias. Ordinary users request builds through the Nix daemon, not by reading the credential.

Pin the Mac's actual OpenSSH public host key in `programs.ssh.knownHosts`. Delete `tailnet-known-hosts.nix`, its fixtures, and all `KnownHostsCommand` wiring. Tailscale's distributed SSH keys authenticate a different server and cannot verify this endpoint. A changed host key must fail until the operator verifies and declares its replacement.

### 5. Remote builds and Linux isolation

`korolev` enables distributed builds and builder substituters. One `ssh-ng` machine derives its host name, username, and measured logical cores from the Mac declaration. It supports `aarch64-darwin` and `big-parallel` and uses the dedicated client key.

`services.tailscale` on `korolev` sets `--shields-up`, disables Taildrop, and opens no firewall port. Its authenticated-state runner preserves the setting across first-time enrollment. No SSH server or other inbound service is added.

`tailnet-builder-check` builds a unique Darwin derivation containing the builder's architecture and hostname, checks `arm64` and `macbook-pro`, and records `tailscale ping` output. Its nonce prevents a cached output from posing as a live remote build. A disconnected builder must fail within the declared connection timeout and recover after reconnection.

### 6. Declarative WSL DNS

Disable WSL `generateResolvConf`, enable `systemd-resolved`, and declare the measured Windows DNS-tunneling upstream `10.255.255.254`. Tailscale supplies the MagicDNS split domain through resolved. A real distribution restart must preserve both employer/public resolution and the Mac's tailnet resolution. Evaluation alone cannot complete this gate.

### 7. Temporary Air integration

The SSH aliases and SMB endpoint use `macbook-air`. Preserve the existing Secure Enclave client authentication and batch transport rules. The SMB agent uses Tailscale peer state for reachability. Live acceptance requires enrolled nodes, activated client configuration, SSH probes, and online/offline mount behavior.

No durable builder, storage, authentication, activation, or release gate depends on the Air. The offboarding issue requires preservation of research results, node revocation before return, then removal of the declaration, policy, SSH/SMB endpoints, credentials, and Air role. The future physical return does not keep this change open.

## Verification and Migration

1. Verify provider claims and separate validation/deployment identities. Verify branch protection and the workflow on actual PR and main events. Keep external acceptance tasks open until those events occur.
1. Generate the root-owned client key; read the Mac's existing public host key through the authenticated channel. Declare only public material and the private key's path.
1. Build both host systems and run deterministic gates. Smoke-test native OpenSSH command success, nonzero exit, rejected keys, host-key mismatch, and tailnet-only listening. Unprivileged test-server evidence does not prove the root launchd or PAM configuration.
1. Review and merge before Mac activation. Activate from a local administrator session so a transport failure cannot strand recovery. Confirm Tailscale SSH is disabled, Apple Remote Login is off, the dedicated daemon listens only on tailnet addresses, and native SSH returns the remote status.
1. Activate the WSL client with its already-provisioned credential. Run the unique remote build, all-system checks, and native Darwin store inspection over the new endpoint. Exercise disconnect/reconnect with a local recovery path on the Mac.
1. Restart WSL and complete DNS acceptance. Enroll unmanaged peers and complete the Air's activated SSH/SMB acceptance.
1. Keep the previous Nix generations until every applicable gate passes. Roll back locally if SSH cutover fails. A generation rollback does not erase client or host private keys, Tailscale enrollment, or application runtime state. Revoke compromised credentials explicitly.

A main revision can advance between the deployment freshness check and the provider write. There is no cross-service transaction; serialization lets the current checked apply finish before a newer checked apply. Tailscale control-plane disruption may delay new network state, but no fallback exposes a LAN listener or bypasses key verification.
