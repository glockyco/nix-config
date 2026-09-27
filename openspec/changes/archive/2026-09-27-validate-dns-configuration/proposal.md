## Why

The DNS zone has an apex TXT RRset with inconsistent TTLs. DNSControl reports a warning but still reports no errors, and repository gates do not check the zone (`dns/dnsconfig.js:6,19,76`, `flake.nix:281-710`, `.github/workflows/check.yml:41-59`).

## What Changes

- Add an offline DNSControl zone check to the repository checks on every supported system. Reject errors and warnings.
- Give both apex TXT records the same TTL without changing other record types.
- Format `dns/dnsconfig.js` through the shared treefmt configuration.
- Record a DNSControl preview for review before the owner applies the zone. Keep the Cloudflare token out of repository checks.

## Capabilities

### New Capabilities

- `dns-zone`: Defines validation and controlled publication of the declared DNS zone.

### Modified Capabilities

None. The existing shared formatting gate already applies to new formatters (`openspec/specs/repository-quality-gates/spec.md:9-26`).

## Impact

- `dns/dnsconfig.js`, `treefmt.nix`, and the check module created by `key-fleet-by-host` gain declarations or checks.
- The Nix check depends on DNSControl on both systems, but the Linux development shell gains DNSControl only if the check requires it there.
- The Mac DNS credential stays in the opt-in Home Manager secret and never enters a Nix build (`modules/home/darwin/secrets.nix:26-32,59-73`, `flake.nix:816-824`).

## Scheduling — 2026-09-26

The owner scheduled this change after plan review. It runs at position 5, after `package-user-programs` is implemented and passes the Mac gates. It uses the check module that `key-fleet-by-host` creates. Changes 1 through 5 archive in order, each after its owner gates pass.
