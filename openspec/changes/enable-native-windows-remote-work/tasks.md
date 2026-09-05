## 1. Establish desktop prerequisites

- [ ] 1.1 Obtain authenticated local or RDP access with owner-entered credentials. Verify the actual desktop identity, Windows edition/build, supported security-update status, and intended non-administrator account. Stop before deployment if support or authorization is missing.
- [ ] 1.2 Inventory native tools, SSH/RDP/SMB services, effective firewall rules, shares, session limits, and power settings. Capture only change-owned settings for rollback and verify a separate local administrator recovery session remains available.
- [ ] 1.3 Select exact native OMP, plugin source, psmux, and dependency versions with upstream provenance. Verify Windows artifacts exist and the plugin revision matches its recorded source; do not install a Nix-store payload or WSL launcher.

## 2. Establish authenticated native SSH

- [ ] 2.1 Configure Windows OpenSSH Server, PowerShell 7, public-key-only access for the selected account, and SFTP. Verify effective server configuration and authorization-file ACLs locally before exposing the listener.
- [ ] 2.2 Restrict effective SSH access to the Tailscale interface and supported address families. Verify no broader rule defeats that restriction and a local recovery path still works.
- [ ] 2.3 Enroll separate Pro and Korolev user public keys through the trusted desktop session. Pin the measured server key in their existing configuration owners. Verify each saved `desktop` entry authenticates without password fallback; keep the Mac builder key unchanged.
- [ ] 2.4 Exercise native commands, paths containing spaces, and exit status 23 from both sources. Verify rejection of an unapproved client key and a deliberately mismatched temporary client host-key record without modifying the server key.

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
- [ ] 4.5 Select or create a bounded transfer folder with owner approval. Configure SMB share and NTFS permissions without guest access or new whole-disk shares. Verify graphical browsing from the Macs, authenticated access from Korolev, round-trip hashes, and denied unauthorized/read-only writes. Inspect inherited SMB exposure and scope effective rules to Tailscale.

## 5. Verify integrated operation and recovery

- [ ] 5.1 Compare successful tailnet access with denied non-tailnet access for SSH, RDP, and SMB from a source with demonstrated LAN reachability. Verify IPv4 and IPv6 where available and inspect effective rules; record unavailable coverage rather than accepting route failures as firewall proof.
- [ ] 5.2 Coordinate a source on a different physical network and exercise saved-name SSH, RDP, and file access. Record actual results without introducing router port forwarding.
- [ ] 5.3 Enable supported unattended Tailscale operation and inspect remote-service startup. Coordinate one desktop reboot with local disk-unlock recovery available. Verify remote access before interactive Windows sign-in, then explicitly resume saved agent history without automatically restarting or replaying work.
- [ ] 5.4 Repeat setup state checks and exercise restoration of one change-owned service setting through local recovery. Verify no duplicate rules, keys, or shares and no deletion of repositories or agent state; return to the accepted configuration afterward.
- [ ] 5.5 Verify Korolev still rejects incoming fleet connections and run the existing live Mac builder and command-status checks. Preserve previous generations and leave unrelated `connect-fleet-over-tailnet` gates unchanged.

## 6. Deliver verified operating guidance

- [ ] 6.1 Extend one existing focused operating document with desktop setup, connection, session-lifetime, version, revocation, and rollback instructions. Add only a concise README entry. Verify commands against the accepted Windows installation and links in rendered documentation; do not create another inventory or architecture manual.
- [ ] 6.2 Record acceptance evidence and remaining limitations with this change. Remove only spike-owned files and sessions after verification. Confirm no hosted collab, custom broker, WSL installation, automatic agent restart, or employer Windows changes were introduced.
- [ ] 6.3 Run `openspec validate enable-native-windows-remote-work --strict` and `nix fmt -- --fail-on-change`. For any Nix/client changes, run the repository release gates: `nix flake check --print-build-logs`, `nix run .#check-darwin-build-plans`, and `nix build .#darwinConfigurations.macbook-pro.system` using the required native hosts. Record unavailable gates explicitly.
- [ ] 6.4 Inspect task-owned staged changes and create atomic commits after their applicable verification. Verify all required runtime gates have evidence before archive; do not substitute artifact completion for working desktop access or push without authorization.
