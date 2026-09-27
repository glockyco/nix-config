## Scheduling — 2026-09-26

The owner scheduled this change after plan review. It runs at position 5, after `package-user-programs` is implemented and passes the Mac gates. It uses the check module that `key-fleet-by-host` creates. Changes 1 through 5 archive in order, each after its owner gates pass.

## 1. Offline Validation Proof

- [x] 1.1 Run `dnscontrol check` from `dns/` in a network-isolated Nix sandbox with only tracked DNS files and DNSControl. Unset the live token. Record the command, sandbox setting, output, and exit status in this change's evidence. If a credential value is required, retry with a nonsecret placeholder. If provider access is required, stop and revise the design before implementing a gate.

## 2. DNS Zone and Repository Checks

- [x] 2.1 Add `checks/dns-zone.nix` and wire it from `flake-modules/checks.nix` for every system. Build the check in a sandbox and prove that errors or warnings from either output stream make it fail, including the current TTL warning. Keep real credentials out of the derivation.
- [x] 2.2 Add `TTL(3600)` to the SPF apex TXT record in `dns/dnsconfig.js`. Prove that the offline DNSControl check now reports no warnings and both apex TXT records use TTL 3600.
- [x] 2.3 Add Prettier to `treefmt.nix` for `dns/dnsconfig.js` only. Format that file, inspect its diff, and prove that `nix fmt -- --fail-on-change` accepts the tracked tree without selecting unrelated JavaScript.
- [x] 2.4 Keep DNSControl in the Darwin-only development shell unless task 1.1 proves the check needs a Linux shell command. Verify the evaluated shell package lists on both systems and document any change to this decision.

## 3. Integration and Publication

- [x] 3.1 Update the README's DNS/release guidance to identify the offline check and the owner-only publication step. Prove the commands match the implemented check and preview workflow.
- [x] 3.2 Run strict OpenSpec validation and the local release gates (`nix fmt -- --fail-on-change`, `nix flake check --print-build-logs`). Record results and prove the DNS check passes on the Mac.
- [x] 3.3 Run `dnscontrol preview` from `dns/` on the Mac with the opt-in DNS token. Record its exact output in this change's evidence and identify every intended TTL change. Do not push.
- [ ] 3.4 Owner: Run the Korolev release gate and record the Linux DNS check result, because this Mac has no Linux builder.
- [ ] 3.5 Owner: Trigger or review CI after authorized publication of the branch, and record both platform job results.
- [ ] 3.6 Owner: Review the recorded DNSControl preview, then run `dnscontrol push` from `dns/` with the opt-in token. Record the result. Do not archive before this task succeeds.
