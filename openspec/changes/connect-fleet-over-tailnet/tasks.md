## 1. Tailnet Account and Trust

- [x] 1.1 Create the tailnet, enable MagicDNS, and record the tailnet ID in the runbook; confirm that the admin console shows MagicDNS enabled and zero nodes.
- [x] 1.2 Create a federated identity for `glockyco/nix-config` with the `policy_file` scope and add `TS_OAUTH_ID`, `TS_AUDIENCE`, and `TS_TAILNET` as repository secrets; confirm with `gh api repos/glockyco/nix-config/actions/secrets` that exactly those three names exist.
- [x] 1.3 Enable "Prevent edits in the admin console" with this repository as the external reference, and confirm that the policy editor shows the lock.

## 2. Host Declarations

- [x] 2.1 Add `host.tailnet.tag` and `host.tailnet.reachable` to `modules/fleet/host.nix`, declare `tag:macbook-pro` and `tag:korolev` with `reachable = false` for `korolev` in `hosts/*/default.nix`, and confirm both hosts evaluate the new values.
- [x] 2.2 Extend `packages/host-declaration-check.nix` with a fixture that omits the tag and one with a malformed tag, and confirm that both are rejected under `deepSeq`.
- [x] 2.3 Add `modules/shared/tailnet-peers.nix` with each peer's tag, lifecycle, and purpose. Mark the desktop durable and the Air temporary for research-result access. Export the data from `modules/shared/default.nix`, and confirm that `moduleImports` still passes.

## 3. Policy Renderer

- [x] 3.1 Add `packages/tailnet-policy.nix` that renders `policy.hujson` from the host declarations and peer data per design decision 2, expose it as `packages.tailnet-policy` on every system, and confirm that `jq` parses the output and that `dst` lists contain no `tag:korolev`.
- [x] 3.2 Add the `tests` and `sshTests` blocks and confirm that the rendered file names every reachable tag as a source that must be denied TCP `tag:korolev:22`. The renderer assertion covers every port because no access or SSH rule may name `tag:korolev` as a destination; Tailscale policy tests require one numeric port per destination.
- [x] 3.3 Add the `tailnetPolicy` check and confirm that `nix build .#checks.x86_64-linux.tailnetPolicy` passes.
- [x] 3.4 Add `tailnetPolicyRejects` with fixtures that name `korolev` as a destination, contain an `@`, and omit a temporary peer's lifecycle or purpose. Confirm every rejection, then remove one renderer assertion temporarily and confirm the check fails before reverting the probe.
- [x] 3.5 Add a policy fixture without the temporary Air peer. Confirm that no tag owner, grant, SSH rule, or test names `tag:air` and that every durable topology invariant passes.
- [x] 3.6 Add `.github/workflows/tailnet-policy.yml` with `test` on pull requests and `apply` on `main`, using the federated identity and `policy-file: result/policy.hujson`; open a pull request and confirm that the `test` job passes against the live tailnet.
- [x] 3.7 Merge and confirm in the admin console that the applied policy equals the rendered file and that the tests block passed.

## 4. Darwin Host

- [x] 4.1 Add `modules/darwin/tailscale.nix` with `services.tailscale.enable`, the `extraSetFlags` option, and the `tailscaled-set` launchd daemon per design decision 3, import it from `modules/darwin/default.nix`, and confirm that the Darwin system evaluates and that `services.openssh.enable` is `null`.
- [x] 4.2 Correct the `trusted-users` rationale in `modules/darwin/nix.nix` to name the remote builder's unsigned imports, and confirm that the rendered `nix.conf` value is unchanged.
- [x] 4.3 Add the `macbookProTailnet` check per design decision 8 and confirm that it passes on `aarch64-darwin`.
- [x] 4.4 Open the nix-darwin pull request that adds `services.tailscale.extraSetFlags` with the NixOS semantics, and record its URL in the decision log entry.
- [ ] 4.5 Activate the Mac, run `tailscale up --advertise-tags=tag:macbook-pro` once, and confirm that `tailscale status --json` reports the tag, `"SSH"` in the node's capabilities, and that `systemsetup -getremotelogin` reports `Off`.
- [ ] 4.6 From the Air, run `ssh glockyco@macbook-pro` and confirm that the tailnet requires re-authentication and then opens the session; from the Mac, run `tailscale ping korolev` after task 5.6 and confirm that it is refused.
- [ ] 4.7 Make `tailscaled-set` wait for `BackendState` to become `Running`, add a state-transition regression check, merge the fix, and confirm on the Mac that `RunSSH` becomes true after activation without an imperative `tailscale set` command.

## 5. Linux Host

- [ ] 5.1 Add `modules/nixos/tailscale.nix` per design decision 5, import it, and confirm by evaluation that `extraSetFlags` contains `--shields-up` and no `--ssh`, that `openFirewall` is false, and that `disableTaildrop` is true.
- [ ] 5.2 Set `wsl.wslConf.network.generateResolvConf = false`, enable `services.resolved`, and declare `networking.nameservers = [ "10.255.255.254" ]`; activate, restart the distribution, and confirm that `resolvectl status` names that upstream and that an employer name and a public name both resolve.
- [ ] 5.3 Add `packages/tailnet-known-hosts.nix` and `packages/tailnet-known-hosts-tests.nix` per design decision 4, wire the test as `tailnetKnownHostsCommand`, and confirm that the fixture for a matching peer prints one `known_hosts` line per key and the other two fixtures exit nonzero.
- [ ] 5.4 Add the `Host macbook-pro` block to `programs.ssh.extraConfig` with `KnownHostsCommand`, `BatchMode yes`, `ConnectTimeout 8`, `ControlMaster no`, and `ControlPath none`; confirm with `ssh -G macbook-pro` as root that every value is present.
- [ ] 5.5 Add `nix.distributedBuilds`, `builders-use-substitutes`, and the `nix.buildMachines` entry derived from the Mac's host declaration; confirm that `/etc/nix/machines` names `glockyco@macbook-pro aarch64-darwin` with no key path and `ssh-ng`.
- [ ] 5.6 Activate `korolev`, run `tailscale up --advertise-tags=tag:korolev` once, and confirm that `tailscale status` reports the tag, that `getent ahosts macbook-pro` returns a `100.64.0.0/10` address, and that `korolevIsolation` still passes.
- [ ] 5.7 As root, run `ssh macbook-pro 'command -v nix-daemon'` and confirm that it prints a path under `/nix` without a prompt; record the measured path in the runbook.
- [ ] 5.8 Extend `korolevIsolation` per design decision 8 and confirm that it passes; then confirm with a temporary probe that adding `--ssh` to the set flags makes it fail, and revert the probe.

## 6. Remote Builder Proof

- [ ] 6.1 Add `packages/tailnet-builder-check.nix` per design decision 8 and install it on `korolev`; run it and confirm that it reports `arm64`, `macbook-pro`, and the `tailscale ping` path.
- [ ] 6.2 Run `nix build .#checks.aarch64-darwin.darwinSystem --print-build-logs` on `korolev` and confirm that the log names the builder and that the output path appears in the local store.
- [ ] 6.3 Run `nix flake check --all-systems --print-build-logs` on `korolev` and confirm exit 0; compare each `aarch64-darwin` check's derivation path with `nix flake check` output on the Mac at the same revision and confirm equality.
- [ ] 6.4 Run `ssh macbook-pro nix run <flake-ref>#check-darwin-build-plans` from `korolev` and confirm that it reports the same result as the local run on the Mac.
- [ ] 6.5 Stop `tailscaled` on the Mac and confirm that a Darwin build from `korolev` fails within the connection timeout with a message that names `macbook-pro`; restart it.

## 7. Retire `.local`

- [ ] 7.1 Install and authenticate the Tailscale application on the temporary Air with `tag:air` and on the durable desktop with `tag:desktop`. Confirm that both appear in `tailscale status` on the Mac.
- [ ] 7.2 Change `modules/home/darwin/ssh.nix` to `HostName = "air"`, and confirm with `ssh -G air` and `ssh -G air-batch` that both resolve `hostname air` and keep their existing transport policy.
- [ ] 7.3 Change `modules/home/darwin/network-shares.nix` to the tailnet name and the peer-state reachability probe, activate, and confirm that `~/Air` resolves while the Air is online and that the agent exits 0 without mounting while it is offline.
- [ ] 7.4 Update `packages/air-batch-config-check.nix` and `packages/air-batch-check-tests.nix` to the new name, run `air-batch-check`, and confirm that all four probes pass over the tailnet.
- [ ] 7.5 Confirm that no file under `modules/`, `packages/`, `hosts/`, or `docs/` contains `.local` as a host suffix or the string `MacBook-Air-von-ISYS`.
- [ ] 7.6 Create a planning issue titled `Retire borrowed Air after research-result retrieval`. Require preserved thesis and TOSEM results, node revocation before return, removal of the tag and policy entries, removal of SSH and SMB configuration and credentials, and removal of the Air role and declaration. Confirm the issue has the `planning` label and links the temporary peer declaration.

## 8. Verify the Complete Change

- [ ] 8.1 Run `nix fmt -- --fail-on-change`.
- [ ] 8.2 Run `nix flake check --all-systems --print-build-logs` on `korolev` with the host's Nix and confirm exit 0.
- [ ] 8.3 Run `nix flake check --print-build-logs`, `nix build .#darwinConfigurations.macbook-pro.system`, and `nix run .#check-darwin-build-plans` on the Mac and confirm exit 0.
- [ ] 8.4 Run `openspec validate connect-fleet-over-tailnet --strict`.
- [ ] 8.5 Review the final diff and confirm that no SSH private key path, no `.local` name, no LAN address, and no e-mail address entered the repository.

## 9. Documentation

- [ ] 9.1 Add a decision-log entry to `docs/architecture/personal-omp-environment.md` that records the reversed `korolev` isolation decision, the durable-host versus temporary-peer boundary, the Air offboarding issue, and the nix-darwin pull request. Update the `WSL work machine` ownership paragraph, and confirm that the entry names the date.
- [ ] 9.2 Add a "Join the tailnet" section to `docs/operations/wsl-omp-bootstrap.md` with the one-time `tailscale up` command, the resolver check from task 5.2, the `nix-daemon` path from task 5.7, and the `tailnet-builder-check` command; confirm that `nix fmt -- --fail-on-change` passes on the file.
- [ ] 9.3 Update the README ownership table, layout table, and Develop section to name the tailnet, the policy workflow, and `nix flake check --all-systems` from `korolev`; confirm that `nix fmt -- --fail-on-change README.md` passes.
