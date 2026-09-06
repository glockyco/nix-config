## Execution priority: 2026-09-06

The owner approved Pro-only SSH/SFTP access before the native agent and broader client rollout, to enable a separate YNAB migration. Complete desktop support, identity, account, and local-recovery checks first. Then perform the Pro portions of tasks 2.1–2.4, the SFTP transfer check in 4.4, and applicable network-isolation checks in 5.1. Neither psmux nor SMB is a prerequisite for this transfer.

Keep multi-source tasks unchecked until every named source passes. Preserve all remaining acceptance gates; this order does not reduce the change's scope. Review the selected Windows account's file permissions before wider enrollment. Desktop-access authorization does not authorize financial-data replication to Korolev or the borrowed Air.

## Pro acceptance evidence: 2026-09-06

The owner reports desktop inventory and version selection complete, with evidence retained on Windows. The reported server configuration uses PowerShell 7, public-key-only authentication, SFTP, and a tailnet-only firewall rule with the broad rule disabled. Three labelled public keys are enrolled. Unattended Tailscale is applied; reboot acceptance remains outstanding.

The owner confirmed the desktop's measured ED25519 fingerprint: `SHA256:ZYFVPT8M8AJI7Vmq63k018DCGIIJKA8atz3xQ6TI4Lw`. The Pro pinned the matching public key for `desktop` and `desktop.tail8768af.ts.net` in its mutable `~/.ssh/known_hosts`. The Pro subsequently integrated the desktop client declaration from `0449822` and added an immutable host-key pin through `UserKnownHostsFile`. Both aliases enforce strict host checking and reject password fallback. The generated configuration was exercised with `ssh -F`; it has not been activated system-wide.

Pro checks used `StrictHostKeyChecking=yes`, `BatchMode=yes`, disabled connection multiplexing, and an eight-second connection timeout:

- Authentication returned `desktop-dbhlrdd\user` and PowerShell `7.6.5`.
- Direct remote `exit 23` returned SSH status `23`. A nested PowerShell invocation without explicit exit forwarding returned `1`; use the direct command for this acceptance check.
- A temporary mismatched host pin failed with status `255` and host-key verification failure.
- A temporary unapproved client key, with the agent disabled and `IdentitiesOnly=yes`, failed with status `255` and `Permission denied (publickey)`.
- A 4,114-byte binary SFTP payload round-tripped through a temporary Windows filename containing spaces. SHA-256 matched: `e7da80720257726b2bf9cf4f4a78307f3a50312b899bfef23a9846ef142eba15`. Windows absolute SFTP paths require `/C:/...`; `C:/...` was treated as relative and failed before creating a file. Remote and local smoke files and temporary keys were removed.
- Read-only metadata confirmed `D:\Projects\ynab` exists, already contains `.git`, and includes `statements` and `.venv`. No project content was copied or executed.

**Accepted administrator access:** the live SSH token reports `WindowsPrincipal.IsInRole(Administrator) = true`. The owner confirmed this account choice and the desktop branch revises tasks 1.1 and 2.1 accordingly. SSH commands have enabled administrator privileges without an additional elevation prompt. Explicit approval for privileged service changes remains an operator policy, not a technical restriction of this SSH account.

The generated `desktop` and `desktop-batch` aliases both authenticated as the selected account. The batch alias returned direct exit status `23`, rejected a mismatched pin and an unapproved client key with status `255`, and passed a second 4,114-byte SFTP round trip through a path with spaces. Its SHA-256 was `79c2b3b3bdb2113c14ce49b43beaf962376b68d4e9c6bcd32ef95e67893f536f`. All temporary files and keys were removed. Server `sshd -T` includes `sk-ssh-ed25519@openssh.com`; an actual YubiKey-authenticated session was not exercised.

**Post-quantum warning:** the installed Windows OpenSSH 9.5 server offers no hybrid key exchange. Its bundled `ssh -Q kex` lists none, and `sshd_config` has no explicit `KexAlgorithms` override. The [Win32-OpenSSH 10.0.0.0p2 preview](https://github.com/PowerShell/Win32-OpenSSH/releases/tag/10.0.0.0p2-Preview) adds ML-KEM and sntrup support but is labelled non-production ready. No server upgrade or warning suppression was applied. A preview compatibility spike and any service replacement require separate owner coordination with local recovery. The warning concerns key exchange, not the verified ED25519 host identity.

Pro transport checks do not complete the multi-source tasks. Korolev/Air acceptance, installed-client activation, non-tailnet rejection coverage, and reboot verification remain outstanding. No Windows server settings were changed from the Pro.

### Native integration gates

The Pro completed the following checks for the integrated desktop client declaration:

- `nix fmt -- --fail-on-change`: passed after applying nixfmt's layout to the host-pin expression.
- `openspec validate --all --strict`: 13 passed, 0 failed.
- `nix build --no-link --print-build-logs .#checks.aarch64-darwin.airBatchConfiguration`: passed. The check exercises OpenSSH's rendered policy for both endpoint pairs and the desktop's immutable pin.
- `nix flake check --print-build-logs`: completed successfully on Darwin; Linux checks were omitted by the native-system selection.
- `nix run .#check-darwin-build-plans`: passed; 34 outputs, none reaching a forbidden source build.
- `nix build .#darwinConfigurations.macbook-pro.system`: completed successfully. No activation or push occurred.

The successful build was not warning-free. Nix emitted ignored evaluation-cache contention and an `options.json` store-context warning. The Catppuccin FZF and Ghostty derivations logged segmentation faults in the Nixpkgs `audit-tmpdir.sh` pipeline but continued successfully. These dependency-build diagnostics were not fixed or suppressed by this client change; retain them for dependency investigation rather than describing the logs as clean.

## 1. Establish desktop prerequisites

- [x] 1.1 Obtain authenticated local or RDP access with owner-entered credentials. Verify the actual desktop identity, Windows edition/build, supported security-update status, and the account selected for remote access. Stop before deployment if support or authorization is missing.
- [x] 1.2 Inventory native tools, SSH/RDP/SMB services, effective firewall rules, shares, session limits, and power settings. Capture only change-owned settings for rollback and record the available local recovery path.
- [x] 1.3 Select exact native OMP, plugin source, psmux, and dependency versions with upstream provenance. Verify Windows artifacts exist and the plugin revision matches its recorded source; do not install a Nix-store payload, and do not accept a WSL launcher as a native tool.
- [ ] 1.4 Record the desktop's independent remote-access products with their effective firewall scope, and note that the tailnet restriction in this change covers only the services it configures.

## 2. Establish authenticated native SSH

- [x] 2.1 Configure Windows OpenSSH Server, PowerShell 7, public-key-only access for the selected account, and SFTP. Disable password *and* keyboard-interactive authentication in the global section, and verify effective server configuration and authorization-file ACLs locally before exposing the listener.
- [x] 2.2 Restrict effective SSH access to the Tailscale addresses and supported address families. Disable the installer's all-profiles rule, verify no broader rule defeats the restriction, and keep the local recovery path working.
- [ ] 2.3 Enroll the Pro, Air, and Korolev source public keys through the trusted desktop session with per-source labels. Pin the measured server key in their existing configuration owners. Verify each saved `desktop` entry authenticates without password fallback; keep the Mac builder key unchanged.
- [ ] 2.4 Exercise native commands, paths containing spaces, and exit status 23 from each source. Verify rejection of an unapproved client key and a deliberately mismatched temporary client host-key record without modifying the server key. Confirm the security-key algorithm is accepted, or scope it explicitly.
- [x] 2.5 Declare the desktop's interactive and unattended client endpoints alongside the existing Air pair, and extend the batch endpoint checks to cover both destinations.

## 3. Prove the native agent and persistent terminal

- [ ] 3.1 Install the selected native OMP executable and required Windows tools through supported installers. Load the pinned personal plugin source through its supported flags. Verify actual SSH-session command resolution and local provider login without transferring credentials.
- [ ] 3.2 Run a harmless agent task in a disposable Windows checkout. Verify native PowerShell and Git execution, personal commit preview, OpenSpec discovery, a local Python research-helper invocation, and representative required language-server diagnostics. Block on any missing personal capability instead of suppressing it.
- [ ] 3.3 Install the selected psmux release and create a named OMP session using upstream commands. Verify terminal rendering, resize, Unicode, paste, interrupt handling, and local-only multiplexer control endpoints without unsafe mouse overrides.
- [ ] 3.4 Detach deliberately and reattach from Korolev to a Pro-initiated session. Verify the same agent process and pending interaction remain usable, then submit another prompt.
- [ ] 3.5 Terminate the initiating SSH client during a bounded harmless agent task. Verify work continues, reattach from the other source, inspect its result, and submit another prompt. Do not mark this gate complete through RDP or history-based restart.

## 4. Complete graphical and file access

- [ ] 4.1 Configure the Air's independent desktop public-key authorization and saved SSH entry. Verify native command success and failure status. Prove selective revocation with a temporary test authorization, then add the Air key-removal action to its existing offboarding owner without prematurely revoking required access.
- [ ] 4.2 Inspect and preserve existing RDP settings where suitable. Keep NLA and screen locking; scope effective RDP rules, including UDP if enabled, to Tailscale. Verify server certificate identity through the trusted local session before saving client connections.
- [ ] 4.3 Provide and exercise RDP clients on Pro, Air, and Korolev without modifying Korolev's Windows host. Start a harmless terminal task, disconnect, and reconnect as the same Windows user. Verify the task and session survived and inspect effective disconnected-session limits.
- [ ] 4.4 Transfer a disposable file over SFTP from each source and verify round-trip hashes. Confirm working checkouts remain on local Windows storage rather than a mounted share.
- [ ] 4.5 Inspect the existing shares and record them with their share and NTFS permissions. Remove the redundant explicit whole-volume shares that duplicate the platform's administrative shares, with owner confirmation per share, and add no new whole-volume or guest-accessible share. Verify graphical browsing from the Macs, authenticated access from Korolev, round-trip hashes, and denied unauthorized/read-only writes. Note that administrator membership, not a share, is what grants whole-volume reach.

## 5. Verify integrated operation and recovery

- [ ] 5.1 Compare successful tailnet access with denied non-tailnet access for SSH, RDP, and SMB from a source with demonstrated LAN reachability. Verify IPv4 and IPv6 where available and inspect effective rules; record unavailable coverage rather than accepting route failures as firewall proof.
- [ ] 5.2 Coordinate a source on a different physical network and exercise saved-name SSH, RDP, and file access. Record actual results without introducing router port forwarding.
- [ ] 5.3 Verify the enabled unattended Tailscale operation and inspect remote-service startup. Disable the desktop's tailnet key expiry and verify the node reports no expiry, matching Korolev and the Pro; an expiring key strands unattended access behind a console re-authentication. Coordinate one desktop restart, using a true restart because Fast Startup is enabled, and record that no volume is encrypted so no preboot unlock applies. Verify remote access before interactive Windows sign-in, then explicitly resume saved agent history without automatically restarting or replaying work.
- [ ] 5.4 Repeat setup state checks and exercise restoration of one change-owned service setting through local recovery. Verify no duplicate rules, keys, or shares and no deletion of repositories or agent state; return to the accepted configuration afterward.
- [ ] 5.5 Verify Korolev still rejects incoming fleet connections and run the existing live Mac builder and command-status checks. Preserve previous generations and leave unrelated `connect-fleet-over-tailnet` gates unchanged.

## 6. Deliver verified operating guidance

- [ ] 6.1 Extend one existing focused operating document with desktop setup, connection, session-lifetime, version, revocation, and rollback instructions. Record the state this repository cannot declare, naming at least the coordination-server key-expiry setting and its verification command, and the unavailability of Taildrop to a tagged node. Add only a concise README entry. Verify commands against the accepted Windows installation and links in rendered documentation; do not create another inventory or architecture manual.
- [ ] 6.2 Record acceptance evidence and remaining limitations with this change. Remove only spike-owned files and sessions after verification. Confirm no hosted collab, custom broker, automatic agent restart, or employer Windows changes were introduced, and that no NixOS-WSL host was declared under this change.
- [ ] 6.3 Run `openspec validate enable-native-windows-remote-work --strict` and `nix fmt -- --fail-on-change`. For any Nix/client changes, run the repository release gates: `nix flake check --print-build-logs`, `nix run .#check-darwin-build-plans`, and `nix build .#darwinConfigurations.macbook-pro.system` using the required native hosts. Record unavailable gates explicitly.
- [ ] 6.4 Inspect task-owned staged changes and create atomic commits after their applicable verification. Verify all required runtime gates have evidence before archive; do not substitute artifact completion for working desktop access or push without authorization.
