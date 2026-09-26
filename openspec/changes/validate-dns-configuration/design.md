## Context

`dns/dnsconfig.js:1-6` selects Cloudflare for `glockyco.com` and sets `DefaultTTL(1)`. The SPF TXT record inherits that TTL (`dns/dnsconfig.js:19`). The Google verification TXT record uses `TTL(3600)` (`dns/dnsconfig.js:75-76`). [RFC 2181 section 5.2](https://www.rfc-editor.org/rfc/rfc2181#section-5.2) requires equal TTLs within one RRset. `dns/creds.json:1-5` references `$CLOUDFLARE_API_TOKEN`. The Mac decrypts the DNS token and exposes it only through an opt-in helper (`modules/home/darwin/secrets.nix:26-32,59-73`).

The Darwin development shell contains DNSControl, but the Linux shell does not (`flake.nix:795-824`). `flake.nix:281-710` declares repository checks without a DNS check. CI runs each system's flake check (`.github/workflows/check.yml:14-22,41-59`). The shared formatter has no JavaScript formatter (`treefmt.nix:17-44`).

## Goals / Non-Goals

**Goals:**

- Fail both system checks for any DNSControl error or warning in the tracked zone.
- Keep offline checks independent of live credentials and provider access.
- Preserve the explicit owner decision to publish only after review.

**Non-Goals:**

- Push DNS changes from a check, CI job, or activation.
- Store a Cloudflare credential or a live provider response in a derivation.
- Change the default TTL for MX, SRV, or other records.

## Decisions

### 1. Prove offline operation before choosing the check implementation

The first implementation task probes `dnscontrol check` in a sandbox with only tracked `dns/dnsconfig.js`, `dns/creds.json`, and the pinned DNSControl executable. Unset `CLOUDFLARE_API_TOKEN` and prohibit network access. Record stdout, stderr, exit status, and the sandbox setting. Repeat with a nonsecret placeholder token only if DNSControl requires a credential value for local validation. Do not use the decrypted Mac token.

If the check succeeds offline, add `checks/dns-zone.nix` and wire it from `flake-modules/checks.nix`, which `key-fleet-by-host` creates. Pass the two tracked DNS files as store inputs. Run from a directory containing their DNSControl names. Capture stdout and stderr. Reject either a nonzero exit or any warning line, including `WARNING: inconsistent TTLs`. DNSControl reports `No errors.` after that warning, so exit status alone cannot protect the RRset. Use a targeted failing TTL fixture or temporary edit as proof that the check rejects a warning.

If DNSControl needs the token's presence but no provider access, pass only the fixed nonsecret placeholder into the sandbox. If it requests the provider despite the isolated sandbox, do not make the check online or silently replace it with a weaker parser. Record the failed probe, keep this change unimplemented, and revise this decision before adding a gate. The fallback is a fail-closed planning gate, not a pass-through check. A separate secret-backed live check is not a substitute for offline CI.

### 2. Set both apex TXT records to TTL 3600

Add `TTL(3600)` to the SPF TXT declaration and keep the verification TXT declaration at `TTL(3600)` (`dns/dnsconfig.js:19,76`). This changes one record and keeps the existing verification TTL. Changing `DefaultTTL(1)` instead would change every record that inherits it (`dns/dnsconfig.js:6,9-19,81-82`). Setting the verification record to TTL 1 would make a long-lived ownership token expire from caches almost immediately. RFC 2181 section 5.2 requires the equal TTLs but does not select their value.

### 3. Limit JavaScript formatting to the zone file

Enable treefmt-nix Prettier only for `dns/dnsconfig.js` in `treefmt.nix`. [Prettier defaults](https://prettier.io/docs/options) to two spaces, double quotes, semicolons, and trailing commas. These match the existing syntax (`dns/dnsconfig.js:1-6,55-59,75-91`). [Biome defaults](https://biomejs.dev/reference/configuration/#javascriptformatterindentstyle) to tabs, unlike this file's two-space indentation. [Deno fmt](https://docs.deno.com/runtime/reference/cli/fmt/) also uses two spaces by default, but adds a general runtime for one file. Neither alternative offers a clear benefit here. Prettier can reflow function calls, so inspect its diff and keep the scoped file selection. The existing shared gate then checks formatting (`treefmt.nix:1-6`, `openspec/specs/repository-quality-gates/spec.md:9-26`).

### 4. Keep the Linux development shell free of deployment tools

A Nix check declares DNSControl as its own build input. That does not require adding DNSControl to `devShells.default` on Linux (`flake.nix:795-824`). Retain the Darwin-only shell package unless the sandbox proof identifies a real shell dependency. Keep live preview and push on the credential-bearing Mac through the opt-in helper (`modules/home/darwin/secrets.nix:59-73`).

## Risks / Trade-offs

- [Offline behavior is unknown] → Measure the sandbox command first. Stop and revise the plan if DNSControl needs provider access.
- [Warning wording can change] → Capture both output streams and prove warning detection with a failing fixture. Treat an unknown warning form as a reason to strengthen the detector, not to ignore diagnostics.
- [TTL 3600 delays SPF updates] → Review `dnscontrol preview` before publication and retain the separate `_dmarc` TTL of 300 (`dns/dnsconfig.js:51-59`).
- [Formatting changes can obscure the TTL edit] → Review the scoped formatter diff separately from the record change.

## Migration Plan

1. Complete the offline probe and implement the per-system check.
1. Align the apex TXT TTLs, format the file, and pass the check on both supported systems.
1. Record `dnscontrol preview` output from the Mac for owner review. Do not push in the implementation task.
1. Owner: Review the preview and run `dnscontrol push` from `dns/` with the opt-in DNS token.

A failed preview or unexpected record change blocks publication. Roll back a published TTL by restoring the prior declaration and asking the owner to review a new preview before a corrective push. The two prior apex TXT TTLs are not a valid final state.
