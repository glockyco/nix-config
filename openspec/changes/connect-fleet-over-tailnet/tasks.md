## 1. Tailnet Account and Trust

- [x] 1.1 Create the tailnet, enable MagicDNS, and record the tailnet ID in the runbook. Initial enrollment prerequisites were completed before the 2026-09-05 review.
- [x] 1.2 Provision separate read-only PR and write deployment federated identities per design decision 2. Record their actual subject format, event/repository/workflow constraints, scopes, and audience associations without logging tokens. Configure `TS_TEST_OAUTH_ID`, `TS_TEST_AUDIENCE`, `TS_OAUTH_ID`, `TS_AUDIENCE`, and `TS_TAILNET`; prove PR credentials cannot authorize policy writes.
- [x] 1.3 Enable prevent-edits in the admin console with this repository as the external reference. The documented administrator override remains a break-glass boundary.
- [x] 1.4 Enforce main protection with current app-bound Linux, Darwin, and policy checks, required PRs, administrator enforcement, linear history, no force-push/deletion, and resolved conversations. The GitHub API accepted these settings on 2026-09-05; owner review remains procedural because the repository has one reviewer.

## 2. Host Declarations

- [x] 2.1 Declare typed tailnet tags and reachability; confirm the Mac is reachable and `korolev` is not.
- [x] 2.2 Reject missing and malformed host tags under `deepSeq`.
- [x] 2.3 Declare the desktop as durable and the Air as temporary with its research-results purpose; export the peer data through the shared module boundary.

## 3. Policy Renderer and Release

- [x] 3.1 Render policy from managed-host and peer data, expose it on both systems, and exclude unreachable tags from grant destinations.
- [x] 3.2 Remove Tailscale SSH rules and `sshTests`; retain provider network tests denying TCP `korolev:22` from every reachable tag.
- [x] 3.3 Update the policy check for the OpenSSH ownership boundary and run it on Linux.
- [x] 3.4 Retain rejection of unreachable grant destinations, account-address input, and incomplete temporary-peer metadata. Remove synthetic-address obfuscation. Prove a missing invariant makes the rejection check fail.
- [x] 3.5 Confirm the fixture without the Air has no Air tag owner, grant, or network test and retains every durable invariant.
- [x] 3.6 Change the workflow to read-only PR validation and serialized deployment after successful main push checks. Render the exact checked SHA, reject obsolete revisions, and fail on freshness-query errors. Exercise real PR validation with the separate identity.
- [x] 3.7 After review and merge, confirm native checks precede apply and the live policy equals that checked revision's rendered policy. Verify failed/PR check completion cannot deploy.

## 4. Darwin Host

- [x] 4.1 Disable Tailscale SSH and Apple's socket-activated Remote Login service. Declare a native OpenSSH launchd daemon bound only to the full MagicDNS name, with public-key-only authentication and the dedicated restricted builder authorization.
- [x] 4.2 Correct the `trusted-users` rationale to the builder's unsigned imports without changing the trusted user.
- [x] 4.3 Update `macbookProTailnet` for the new server and run it on Darwin. Smoke-test native command success/nonzero status, key rejection, host-key mismatch, and restricted-key behavior with a temporary native server.
- [x] 4.4 Record the upstream nix-darwin `extraSetFlags` pull request and its authenticated-state ordering requirement.
- [x] 4.5 After review and merge, activate from a local Mac administrator session. Confirm `RunSSH` is false, Apple Remote Login is off, the dedicated daemon listens only on tailnet addresses, authentication works, and `ssh ... 'exit 23'` returns 23. Verify the root daemon and PAM boundary rather than substituting an unprivileged smoke.
- [ ] 4.6 Confirm a LAN connection cannot reach the new SSH listener and the Mac still cannot initiate access to `korolev`. Use a local recovery path for any network interruption.
- [x] 4.7 Retain the authenticated-state runner and verify it applies `--ssh=false` after `Running`, retries real failures, and never passes unsupported `--advertise-tags` to `tailscale set`.
- [x] 4.8 Materialize the Darwin authorized-key file outside the Nix store, retain `StrictModes`, restore captured authentication logging, and verify the generated daemon cannot regress to a store-backed authorization path.

## 5. Linux Host

- [x] 5.1 Enable Tailscale with shields-up, Taildrop disabled, and no open firewall port.
- [ ] 5.2 Activate resolved with WSL resolver generation disabled and upstream `10.255.255.254`; restart the distribution and confirm employer, public, and MagicDNS resolution persist.
- [x] 5.3 Remove the Tailscale known-hosts helper and its fixtures/callers. Declare the measured OpenSSH host public key and verify changed host keys fail closed.
- [x] 5.4 Configure the root SSH alias with the builder's identity file, identities-only, strict host checking, batch mode, eight-second connection timeout, and no multiplexing. Inspect the actual generated client configuration.
- [x] 5.5 Provision the root-owned client key outside the store and declare its path in the one `ssh-ng` builder. Verify root-only permissions, public-key agreement, and the generated machines file.
- [x] 5.6 Enroll `korolev` with its declared tag and verify its shields-up state and tailnet name resolution.
- [x] 5.7 After activation, use root's new SSH endpoint to confirm the non-interactive `nix-daemon` path and record it in the runbook.
- [x] 5.8 Update and run `korolevIsolation` for the dedicated-key client without weakening any no-inbound invariant.

## 6. Remote Builder Proof

- [x] 6.1 Run the nonce-based `tailnet-builder-check` over OpenSSH; confirm a live build reports `arm64`, `macbook-pro`, and the measured Tailscale path.
- [x] 6.2 Build the Darwin system check from `korolev`; confirm the remote builder runs and its output enters the local store.
- [x] 6.3 Run all-system checks on the combined revision and compare Darwin check derivations with native evaluation of that same revision.
- [x] 6.4 Run the packaged Darwin build-plan inspection from Linux through native SSH and confirm its output and exit status match a local Darwin invocation.
- [ ] 6.5 With local Mac recovery available, disconnect its tailnet, prove a new Darwin build fails within the connection timeout naming the builder, reconnect, and prove a fresh build succeeds.

## 7. Retire mDNS Endpoints

- [ ] 7.1 Install and authenticate Tailscale on the temporary Air and durable desktop with their declared names/tags; confirm both nodes appear.
- [x] 7.2 Change the Air SSH aliases to `macbook-air` while retaining their existing transport policy.
- [ ] 7.3 Activate the tailnet SMB endpoint and peer-state probe; confirm online mounting and offline no-mount behavior.
- [ ] 7.4 Run the four `air-batch-check` probes over the enrolled and activated tailnet path.
- [x] 7.5 Remove legacy mDNS endpoint literals from configuration, packages, hosts, and operating documentation.
- [x] 7.6 Track Air retirement in the planning issue: preserve results, revoke before return, and remove policy, declaration, endpoints, credentials, and role.

## 8. Verify the Combined Revision

- [x] 8.1 Run `nix fmt -- --fail-on-change`.
- [x] 8.2 Run `nix flake check --all-systems --print-build-logs` on `korolev`.
- [x] 8.3 Run native Darwin flake checks, the complete Darwin system build, and the Darwin build-plan guard with trustworthy exit status.
- [x] 8.4 Run `openspec validate connect-fleet-over-tailnet --strict`.
- [x] 8.5 Review the final diff for the approved credential and network boundary: public keys and a private-key path are permitted; private-key material, real account addresses in policy, LAN endpoints, and mDNS endpoints are not.

## 9. Documentation

- [x] 9.1 Record the 2026-09-05 OpenSSH correction, credential trust impact, tailnet-only listener, policy identity separation, deployment protections, and unchanged temporary-peer boundary in the architecture document.
- [x] 9.2 Update the WSL runbook for credential provisioning, root SSH checks, host-key replacement, local Mac activation/recovery, DNS restart acceptance, and live builder verification.
- [x] 9.3 Reconcile the README and dependency-update procedure with the combined native gates and checked policy deployment. Do not report external activation or provider checks as complete before they run.

## Acceptance evidence: 2026-09-05

PR #20 was rebase-merged as `75b2c7a568ea1e3d727774b76aef113c7712f78c`. PR #21 corrected the native authorized-key path and was rebase-merged as `dd445b76ad2444dbea81b00af696554ecf136ce1`.

- Provider identities and their persisted claim restrictions are recorded in the dependency-update runbook. [PR validation run 33960437444](https://github.com/glockyco/nix-config/actions/runs/33960437444) passed. The validation token received HTTP 403 for policy writes, and the deployment identity rejected the PR token with HTTP 403. The PR apply job was skipped.
- [Native main checks 33963089974](https://github.com/glockyco/nix-config/actions/runs/33963089974) passed at `dd445b7`. [Policy deployment 33963623549](https://github.com/glockyco/nix-config/actions/runs/33963623549) followed those checks and selected that exact revision. Its live-control and rendered-policy digests both were `9632358398c5eec87919d3b1d8d1e1a96654bbe9aa95ba0ad04c7530ec6ff71f`. The reviewed apply condition requires a successful main push check. Failed-check rejection is established by that condition, not a deliberately failed main run.
- The owner confirmed successful Mac activation, Tailscale SSH disabled, Apple Remote Login off, and native SSH listening only on the tailnet address. The authorization file is regular `root:wheel` mode `0444`, outside the Nix store. Korolev activated `dd445b7` as generation 17, retained generation 16, and reported `running` with no failed units.
- The installed root SSH alias returned `/nix/var/nix/profiles/default/bin/nix-daemon` with status 0. `exit 23` returned status 23 without output. An unapproved key, forced PTY, remote forwarding, and direct TCP forwarding each failed with status 255. No temporary SSH configuration was needed after Korolev activation.
- The nonce-based installed builder check passed, reporting `arm64`, `macbook-pro`, and a direct Tailscale path. Its log showed execution on the Mac and transfer into Korolev's store.
- `nix build .#checks.aarch64-darwin.darwinSystem --no-link --json --print-build-logs` built through `ssh-ng://glockyco@macbook-pro`. The returned output was `/nix/store/mnmkzgl5kmhgbiya6dlnkwy8vy3l6wqi-darwin-system-26.05.c3e90c8`.
- All-system checks passed on Korolev at `dd445b7`. All 22 Darwin check derivations matched native evaluation of that same revision. Native Darwin flake checks and the complete system build passed through the installed root SSH endpoint. The local Darwin commands and the SSH client returned status 0. The packaged build-plan guard reported 34 outputs with no forbidden source build.

Tasks 4.6, 5.2, 6.5, 7.1, 7.3, and 7.4 remain open. No WSL restart, tailnet disconnection, LAN connection probe, or unmanaged-peer enrollment occurred during this acceptance run.
