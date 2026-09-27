# dns-zone Specification

## Purpose

The DNS zone capability keeps the declared domain records valid on every supported system and reserves publication for the owner after preview review.

## Requirements

### Requirement: Offline DNS zone validation on every system

Every supported system's repository checks SHALL validate the tracked DNS zone with DNSControl without network access or a live credential. A validation error or warning SHALL fail the check.

#### Scenario: Zone validates without diagnostics

- **WHEN** a supported system checks a valid tracked DNS zone in an isolated build
- **THEN** DNSControl validation passes without live Cloudflare access or a secret token

#### Scenario: DNSControl reports a warning

- **WHEN** DNSControl reports a warning for the tracked zone but exits successfully
- **THEN** the repository check fails on that system

#### Scenario: DNSControl reports an error

- **WHEN** DNSControl reports a validation error or exits unsuccessfully
- **THEN** the repository check fails on that system

### Requirement: One TTL for the apex TXT RRset

The `glockyco.com` apex TXT records SHALL have one shared TTL, including the SPF and Google verification records. The check SHALL reject a mismatch.

#### Scenario: Apex TXT TTLs diverge

- **WHEN** the SPF and Google verification TXT records have different TTLs
- **THEN** offline repository validation fails

#### Scenario: Apex TXT TTLs agree

- **WHEN** the SPF and Google verification TXT records both use TTL 3600
- **THEN** the apex TXT RRset produces no inconsistent-TTL warning

### Requirement: The shared formatter covers the DNS declaration

The repository's shared formatting gate SHALL format `dns/dnsconfig.js` without formatting unrelated JavaScript files.

#### Scenario: DNS declaration is not formatted

- **WHEN** the tracked DNS declaration differs from its formatter output
- **THEN** the commit and CI formatting gates reject that difference

### Requirement: Publication follows an owner-reviewed preview

The DNS zone SHALL be published only through an explicit owner action after a review of a recorded DNSControl preview. Repository checks and host activation SHALL NOT publish the zone.

#### Scenario: Repository checks run

- **WHEN** repository checks validate the zone
- **THEN** they do not call the Cloudflare mutation API or require its token

#### Scenario: Owner accepts the preview

- **WHEN** the owner reviews the recorded preview and explicitly runs the push command with the DNS token
- **THEN** DNSControl can publish the reviewed zone changes
