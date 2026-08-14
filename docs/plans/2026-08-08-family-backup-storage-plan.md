# Family Backup, Storage, and Continuity

Status: draft. The architecture is directional; products, capacities, retention,
and legal arrangements remain undecided.

## Goal

Protect personal and shared data across the current MacBook Pro, Windows PCs,
family phones, and dormant cloud accounts. Make recovery routine after device
loss, incapacity, or death while preserving personal privacy and allowing a
clean separation if required.

The university MacBook Air is temporary equipment, not future infrastructure.
It must be reviewed and returned next month without personal accounts or data.

## Principles

- Shared infrastructure, independent identities, explicit shared spaces.
- Cloud sync, RAID, source control, and Nix generations are not backups.
- Keep at least one local versioned copy and one encrypted offsite copy.
- A restore test, not a successful upload, proves a backup.
- Centralize operations where useful, but not everyone's credentials or
  decryption authority.
- Prefer an appliance-style system with low administrative overhead over a DIY
  Raspberry Pi or custom storage server.
- Keep storage separate from any future LLM or agent compute box. Agents receive
  only scoped, preferably read-only access to curated data.

## Data boundaries

Classify data before designing permissions:

- **Personal:** private files, messages, finance, health, and individual device
  backups. Owned and encrypted per person.
- **Shared household:** family photos, contracts, warranties, tax material, and
  other deliberately joint records.
- **Estate and emergency:** account inventory, provider contacts, recovery
  instructions, legal documents, and locations of recovery material. This is a
  map and procedure, not a collection of shared daily passwords.
- **Extended family:** the wife's parents retain separate identities and private
  repositories, with only deliberate family shares and emergency access.

## Directional architecture

- Encrypted Time Machine or equivalent local device backup for each Mac.
- A low-maintenance multi-user NAS as the likely local storage and backup hub.
- Separate per-person backup repositories plus explicit shared datasets.
- Filesystem snapshots and redundant disks for availability; neither replaces
  an independent backup.
- Encrypted offsite replication to an independent provider.
- Windows backup clients and mobile photo/file ingestion selected only after the
  device and data inventory.
- Ecosystem-native phone backup remains necessary for complete iPhone/Android
  device recovery; the NAS may provide an additional photo/file copy.
- Remote family devices connect through managed private networking rather than
  publicly exposed NAS services.

## Continuity and separation

- Each person keeps a personal password vault; household credentials live in an
  explicit shared collection. Never share master passwords.
- Configure Apple Legacy Contact, Google Inactive Account Manager, and carefully
  scoped password-manager emergency access where appropriate.
- Create an Austrian incapacity and estate plan with professional advice,
  including a Vorsorgevollmacht and provider-specific succession procedures.
- Financial accounts such as Flatex transfer through the formal estate process;
  the survivor needs the account inventory and procedure, not the deceased
  person's login for impersonation.
- A separation runbook must let each person export private data, copy jointly
  owned data, rotate shared credentials, and detach devices without affecting
  the other's private repository.
- If protection from a malicious shared administrator is required, each person
  also needs independently controlled encryption or an independent offsite
  copy. Shared administration cannot provide that guarantee by itself.

## Current risks

- The MacBook Pro has FileVault enabled but no Time Machine destination.
- Visible iCloud Drive items are not currently hydrated locally, so local backup
  coverage cannot be assumed.
- SOPS secrets have only the MacBook Pro's local age recipient; recovery is
  currently device-dependent.
- The university MacBook Air has about 723 GiB in use, FileVault disabled, an
  unavailable Time Machine destination, and a Google Drive directory. Only
  personally owned data may be exported; university data and return procedures
  must remain separate.

## Plan

1. **Evacuate the university MacBook Air.** Inventory personally owned files and
   cloud accounts, copy and verify them, sign out of personal services, then
   follow the university's return or erasure procedure. Do not indiscriminately
   copy employer or research data.
1. **Inventory everything.** Record devices, owners, local data size, cloud
   accounts, external disks, recovery methods, and billing. Include the MacBook
   Pro, Windows desktop, wife's Windows machines, all phones, parents' devices,
   iCloud, Google, and dormant providers.
1. **Recover dormant clouds.** Export each provider into an untouched staging
   area, record counts/checksums, and preserve it before deduplication or account
   closure.
1. **Define requirements.** Agree on ownership boundaries, privacy from the
   operator, recovery authorities, retention, acceptable cost, and expected
   growth.
1. **Add immediate local protection.** Configure encrypted local backups before
   attempting consolidation or repurposing devices.
1. **Select the platform.** Compare low-maintenance NAS appliances, disks, UPS,
   client support, snapshots, exportability, and vendor dependence. Choose
   capacity only from the measured inventory.
1. **Add offsite protection.** Select an independent encrypted object-storage or
   managed-backup target and define retention, integrity checks, and alerts.
1. **Fix recovery credentials.** Add an offline SOPS recovery recipient and
   independently recoverable backup credentials without creating a circular
   dependency on the backup itself.
1. **Onboard one person and one device first.** Exercise backup, failure alerts,
   file restore, full-device recovery, privacy boundaries, and export before
   expanding to the rest of the family.
1. **Establish continuity.** Configure platform legacy contacts and create the
   incapacity, death, and separation runbooks. Test recovery without sharing
   ordinary passwords.
1. **Evaluate agent hardware last.** Choose any Mac mini or other compute box
   from measured workloads; do not give it administrative or blanket access to
   backup repositories.

## Decisions still open

- NAS vendor/model, drive count, usable capacity, filesystem, and UPS.
- Backup clients for Windows and mobile photo ingestion.
- Offsite provider, budget, retention schedule, and immutable-storage needs.
- Which data the NAS operator may decrypt and which remains client-encrypted.
- Whether parents use the same physical NAS or an independently operated target.
- Exact legal documents, emergency contacts, waiting periods, and escrow method.
- LLM/agent workloads, required memory, hardware, and permitted data access.

## References

- [Apple Legacy Contact](https://support.apple.com/en-us/102631)
- [Google Inactive Account Manager](https://support.google.com/accounts/answer/3036546)
- [Bitwarden Emergency Access](https://bitwarden.com/help/emergency-access/)
- [Austria: Vorsorgevollmacht](https://www.oesterreich.gv.at/de/themen/gesetze_und_recht/erwachsenenvertretung_und_vorsorgevollmacht/4)
- [Flatex Austria: deceased account holder](https://www.flatex.at/service/faqs/detail/rund-um-konto-und-depot/allgemein-zu-rund-um-konto-und-depot/was-muss-veranlasst-werden-wenn-ein-depotinhaber-verstorben-ist/)

## Done when

Every retained device and cloud account has an owner and disposition; unique
files from the university MacBook Air and dormant providers are safely
recovered; each active device has a monitored local/offsite backup path; every
person can restore and export their data; shared data remains available to the
appropriate family members; and incapacity, death, and separation procedures
have been tested without relying on shared personal passwords.
