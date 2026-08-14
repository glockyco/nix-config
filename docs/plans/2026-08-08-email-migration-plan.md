# Email Migration and Account Cleanup

Status: deferred until the higher-priority infrastructure backlog is complete.

## Goal

Move active accounts from legacy Gmail/A1 addresses to Fastmail, reduce unused
accounts and subscriptions, then retire Fastmail's delayed legacy mail fetchers.

## Address policy

- `johann@glockyco.com`: people, identity, and critical recovery.
- `contact@glockyco.com`: published contact address.
- One Fastmail Masked Email address per service.
- Legacy addresses remain migration sources, not destinations for new accounts.

## Plan

1. Inventory accounts from Bitwarden, old-mail searches, Apple/Google SSO lists,
   and bank/card subscription history.
1. Audit credential recovery by risk. For identity-root accounts, keep a
   hardware or platform passkey and recovery code independent of Bitwarden;
   ordinary accounts may keep passkeys and TOTP in Bitwarden.
1. Classify each as **keep and migrate**, **cancel**, or **review later**.
1. Cancel unused subscriptions before closing accounts; export anything worth
   keeping and revoke sessions, integrations, and API tokens.
1. Migrate kept accounts in risk order: identity/recovery, financial, developer,
   shopping, then low-value services. Change the service first, verify mail and
   recovery, then update its Bitwarden username.
1. Move 2FA recovery addresses last, after the new address and recovery flow are
   proven. Never change email, password, and 2FA in one unverified step.
1. After 6–12 months without important legacy mail, remove the corresponding
   Fastmail fetchers. Keep ownership of old addresses to prevent reuse.

## Done when

No important service depends on a legacy address, every retained service has a
working unique address and recovery path, unused paid services are cancelled,
and legacy fetch delays no longer affect daily mail.
