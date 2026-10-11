# Spec Delta

## MODIFIED Requirements

### Requirement: Explicit update ownership

Central automation SHALL own Nix inputs; Renovate SHALL own Actions/non-Nix dependencies with its beta Nix manager disabled. Mac Nix SHALL supply ordinary host tools, never OMP/plugin runtime. Mac OMP SHALL use official installer/update; Korolev OMP SHALL be Tern-managed and its native tools retain C3's owners. Plugin managers SHALL own runtime upgrades. Plannotator advancement SHALL remain explicit. No target App private key or competing Nix scheduler SHALL exist.

#### Scenario: Inspect updater configuration

- **WHEN** dependency operations, automation and central registry are inspected
- **THEN** each dependency class has one update owner/version authority
- **AND** platform OMP/plugin operations remain outside Nix activation
- **AND** Docker Desktop remains Intune-owned, Mac Colima remains Nix/user-owned and Windows TeX Live/tlmgr yearly lifecycle remains C3-owned
- **AND** no App credential or scheduled Nix-update workflow exists in this repository

### Requirement: Required merge checks

Main SHALL require current Darwin Nix, Linux-generic CI, native Windows, portable OpenSpec and applicable live policy jobs for humans/automation including administrators. It SHALL require an up-to-date PR branch and linear history, rejecting force-push/deletion. Checks SHALL not build the removed Korolev host or depend on its builder.

#### Scenario: A required check fails

- **WHEN** any required platform/OpenSpec/policy check fails
- **THEN** main rejects the merge for human and automated actors, including administrators
- **AND** no removed-host check or Linux-only success satisfies protection

### Requirement: Manual activation boundary

Merges SHALL not activate workstations or mutate OMP state. Nix build/activation SHALL run only on Mac and applicable CI; Windows user apply and platform runtime/plugin updates SHALL remain explicit authorized operations. Agents MAY run authorized commands in an actual terminal while owners type sudo/UAC credentials. Neither publication nor a plan SHALL imply activation authorization.

#### Scenario: Merge a dependency update

- **WHEN** required checks pass and an authorized maintainer merges the PR
- **THEN** active workstations and OMP/plugin selections remain unchanged until explicit platform operations

#### Scenario: Update OMP

- **WHEN** the owner updates the Mac via omp update or Windows via Tern's Check for omp updates
- **THEN** only that platform-owned upstream installation changes
- **AND** no repository/Nix generation changes implicitly
- **AND** evidence records observed installation and a fresh Tern session

### Requirement: Retained rollback

Mac updates SHALL retain the previous Nix generation through activation/session acceptance; Nix rollback SHALL not claim OMP/plugin recovery. Native Windows recovery SHALL use accepted tool/source backups, Tern OMP recovery and supported corrective plugin releases. WSL retirement SHALL require a private retained export; its recovery SHALL be an explicitly authorized import, not a continuing supported environment or state conversion.

#### Scenario: New generation fails acceptance

- **WHEN** Mac activation or release smoke fails
- **THEN** the owner can restore the retained Nix generation without replacing mutable OMP state
- **AND** rollback claims no OMP/plugin-version change

#### Scenario: OMP update fails acceptance

- **WHEN** installed OMP fails direct verification or session smoke
- **THEN** the owner follows supported Mac official-installer or Windows Tern recovery with recorded accepted releases where available
- **AND** no Nix rollback is represented as executable recovery
- **AND** missing recovery prerequisites are reported, not fabricated

### Requirement: Discoverable operations

AGENTS.md, README and the dependency runbook SHALL identify Nix maintenance on Mac/CI, native Windows hooks/apply, portable OpenSpec commands/workflow, platform OMP/plugin ownership and explicit activation/recovery boundaries. Retained-WSL, GPG/pass and daemon-builder instructions SHALL be removed. No substitute scheduler, updater shim or Linux delegation SHALL be introduced.

#### Scenario: Resume in a new session

- **WHEN** an agent receives a maintenance question
- **THEN** guidance points to applicable Mac Nix, Windows native/Tern and plugin-manager operations
- **AND** it references no deleted WSL wrapper/builder/update workflow
- **AND** the Korolev migration/export runbook is discoverable without copying historical WSL instructions into active procedures
