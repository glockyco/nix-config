## Offline validation probe

The Mac's Nix configuration has `sandbox = false`. The probe therefore built a throwaway derivation with `nix build --impure --option sandbox true -f /tmp/dns-probe.nix`. The derivation copied only the tracked `dns/dnsconfig.js` and `dns/creds.json` into its build directory, unset `CLOUDFLARE_API_TOKEN`, and ran the pinned `dnscontrol` 4.39.0.

- In the same sandbox, `curl https://api.cloudflare.com/client/v4` exited 6 with `Could not resolve host: api.cloudflare.com`. The sandbox had no network.
- `dnscontrol check` exited 0 with this output on stdout and nothing on stderr:

```text
1 Validation errors:
WARNING: inconsistent TTLs at "glockyco.com": MX:1 TXT:1,3600
No errors.
```

DNSControl needs no credential value and no provider access for this check. It reports the TTL warning but exits 0, so the repository check must read the report.

## Repository check

`checks/dns-zone.nix` runs the same command in a build and accepts only a report whose only non-empty line is `No errors.`. `flake-modules/checks.nix` wires it as `checks.<system>.dnsZone` for every system.

- Before the TTL fix, `nix build --option sandbox true .#checks.aarch64-darwin.dnsZone` exited 1. It printed the TTL warning and `dns-zone: DNSControl reported a finding (exit 0)`.
- After `TTL(3600)` was added to the SPF record, the same build exited 0. Both apex TXT records now declare `TTL(3600)`.
- `nix eval` of `checks.x86_64-linux` lists `dnsZone`. The Mac has no Linux builder, so owner task 3.4 builds it on Korolev.

## Formatter and shell

`treefmt.nix` enables Prettier with `includes = [ "dns/dnsconfig.js" ]`. The first `nix fmt` changed only that file: it wrapped the `D(...)` call and the Google verification `TXT(...)` call. `nix fmt -- --fail-on-change` then reported `formatted 0 files (0 changed)`. The rebuilt `dnsZone` check passed on the formatted file.

The check declares DNSControl as its own build input, so the development shell needs no change. The evaluated shells list `dnscontrol-4.39.0` on `aarch64-darwin` and no DNSControl on `x86_64-linux`.

## Preview

On 2026-09-27, `dnscontrol preview` ran from `dns/` in the Mac development shell. The token came from the SOPS path that `use_cloudflare_dns` reads and was never printed. It reported one correction:

```text
******************** Domain: glockyco.com
1 correction (cloudflare)
#1: ± MODIFY-TTL glockyco.com TXT ttl=(1->3600) "v=spf1 include:spf.messagingengine.com ~all" id=a8b2580fab9b0286d84a7c34861e88a3
Done. 1 corrections.
```

This is the intended change and the only change. Nothing was pushed.
