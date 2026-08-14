# DMARC Enforcement Rollout

Status: complete. `p=quarantine` is published and is the intended end state.

## Goal

Protect the apex against exact-domain spoofing without losing legitimate mail,
and repair the report feedback loop that made the decision blind.

## Current state

`_dmarc.glockyco.com` is
`v=DMARC1; p=quarantine; sp=reject; np=reject; rua=mailto:dmarc@glockyco.com`
with TTL 300, applied 2026-08-09. Fastmail is the sole sender, and DKIM
alignment already passes on `fm1`. Subdomains carry no mail, so `sp` and `np`
went straight to `reject` while the apex stays at `none`.

The zone is managed declaratively in `dns/dnsconfig.js`; apply every step of
this ladder with `dnscontrol preview` followed by `dnscontrol push`, never by
editing the record in the Cloudflare dashboard.

## Feedback loop, fixed 2026-08-09

`rua` used to point outside the organizational domain, which makes RFC 9990
section 4 apply: the receiving domain must publish an authorization record at
`glockyco.com._report._dmarc.fastmail.com`. Fastmail publishes neither that
record nor a wildcard, so a conforming receiver was obliged to discard every
report. Exactly one aggregate report had ever arrived, from Google, which
evidently does not enforce the check. Outbound volume is also near zero, so
that single report was never by itself evidence that other receivers were
dropping reports; the missing authorization was a defect on its own terms.

`rua` is now the in-domain role address `dmarc@glockyco.com`, which removes the
requirement outright rather than depending on what another operator publishes.
Removing the old URI also took the account's own address out of a public DNS
record.

A role address rather than a tag on an existing one such as
`contact+dmarc@glockyco.com`. Subaddressing would work today and needs no
alias, but it binds the feedback loop to an address this domain is actively
migrating, and it assumes every report generator handles `+` in a `rua` URI,
which is not established. Neither is a good trade for saving one click on a
mailbox that must outlive the person reading it.

The identity and recovery address is not a candidate either. A DMARC record is
public, and the address policy keeps that one deliberately unpublished.

## Outstanding: make the alias explicit

Mail to `dmarc@glockyco.com` is delivered today by the `*@glockyco.com`
catch-all, so publishing the record could not bounce. That is delivery by
accident, not by intent. A catch-all is usually the first thing switched off
once the spam becomes tiring, and the address policy is moving toward one
address per purpose anyway. If it is withdrawn while `dmarc@` exists only
implicitly, reporting dies silently with a public DNS record still pointing at
it.

Fastmail exposes no alias-management API and JMAP has no concept of one, so a
write-scoped token would not help; this is a single action in the web UI.

1. Settings → Users & Sharing → Aliases
   (`https://app.fastmail.com/settings/aliases`). Enter `dmarc`, select
   `glockyco.com` from the domain dropdown rather than the default Fastmail
   domain, and click **Create alias**.
1. Set the delivery target to this Fastmail account itself and save. Delivery
   elsewhere would put the reports in a mailbox the JMAP token cannot read.

Note that sending a test message proves nothing about the alias while the
catch-all is active: it would be accepted either way. Confirm the alias by its
presence in the alias list.

A `DMARC` folder and a filing rule are *not* needed. `fastmail dmarc` matches
on subject across the whole account and does not care which mailbox a report
lands in. Create the folder for tidiness or not at all.

## Why quarantine is the endpoint

`p=quarantine` was published on 2026-08-09 and is where this stops. It is not
a stop on the way to `p=reject`.

Quarantine is where the protection actually arrives: a message spoofing the
apex lands in spam. Reject is a small increment on top of that, and it buys
little for a domain with one sender and no bulk mail. What it costs is the
failure mode: a legitimate sender nobody remembered goes from a recoverable
message in a spam folder to a bounce the sender may never read. Reject remains
available if a reason for it ever appears.

Be clear about what this does not cover. Section 2.4 of RFC 9989 puts display
name attacks and lookalike domains out of scope. DMARC closes exact-domain
impersonation and nothing else; it is the cheapest spoof for an attacker, not
the only one.

It went straight to `quarantine` without `t=y` staging. RFC 9989 removed `pct`
and replaced it with `t`, but section 4.8 requires receivers to ignore unknown
tags, so a receiver still on RFC 7489 drops `t` and enforces at full strength.
Staging with it therefore buys an inconsistent half-measure. What it would
guard against is a sender nobody remembers, and at this volume no observation
window surfaces one of those either. The real controls are that quarantine
fails softly, the TTL is 300 seconds, and the sender inventory is closed by
construction: Fastmail is the only thing that sends as this domain, per-service
addresses are Masked Email on other domains, and aggregate reports show direct
mail aligning on both SPF and DKIM.

## Ongoing check

`fastmail dmarc --failures-only` must stay empty. Anything listed is either a
new legitimate sender that needs its DKIM aligned, or someone spoofing the
domain. Under enforcement this is no longer a gate before a change; it is the
only thing that will tell you a legitimate sender has started landing in spam.

## Known benign source

A1 Telekom (`smtpforward*.a1.net`) appears with SPF fail because the legacy A1
address forwards to a legacy Gmail address and rewrites the envelope sender to
`@a1.net`. SPF alignment is unfixable for forwarded mail
by construction and needs no action; DKIM survives the hop intact, so DMARC
passes. This source disappears when the legacy address is retired under the
[Email Migration and Account Cleanup plan](2026-08-08-email-migration-plan.md).

## Rollback

TTL 300 means reverting the `_dmarc` TXT propagates in minutes. Drop `p` back
to `none` in `dns/dnsconfig.js` and push; nothing else needs touching, and
quarantined mail is still in recipients' spam folders rather than lost.

## Out of scope

MTA-STS, TLS-RPT, and DNSSEC are absent on the zone and are separate work.

## Done when

`p=quarantine` is published, reports arrive at the in-domain address, and
`fastmail dmarc --failures-only` is empty. All three hold as of 2026-08-09.
The remaining open item is making the `dmarc@` alias explicit rather than
relying on the catch-all.
