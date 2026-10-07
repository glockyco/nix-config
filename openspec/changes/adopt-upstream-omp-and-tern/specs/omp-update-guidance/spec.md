## ADDED Requirements

### Requirement: Discoverable upstream update guidance

A fresh upstream OMP session in this repository SHALL find current ownership, official installer commands, `omp update`, and the personal plugin's manager install/upgrade commands through AGENTS.md and README. The repository SHALL contain no wrapper-specific `omp-update` skill, patch-repair procedure, Herdr control prerequisite, or source-generation recovery runbook. Guidance SHALL not require previous conversation history.

#### Scenario: Request an update in a fresh session

- **WHEN** the user asks a fresh upstream session in this repository to update OMP
- **THEN** repository guidance identifies the official executable and plugin-manager update operations
- **AND** it is sufficient to determine the next authorized action without a previous transcript

#### Scenario: Format authored guidance

- **WHEN** the repository formatter processes the update guidance
- **THEN** its links and commands still identify the official updater and published plugin
- **AND** no deleted skill or source-updater link is restored
- **AND** a second formatting pass makes no further changes

### Requirement: Installed upstream host discovery

The guidance SHALL determine the target host, official command path/version, plugin-manager installation identity/version, and requested scope before mutation. It SHALL default to the current host and SHALL NOT treat a Nix check-tool pin, previous session, or another host's evidence as the current runtime. Native Windows and WSL installations SHALL be distinguished.

#### Scenario: Check tools and installed plugin differ

- **WHEN** the reviewed build-time plugin/check input differs from the user's installed plugin release
- **THEN** the agent identifies their separate ownership
- **AND** it does not activate Nix to claim that the runtime plugin was upgraded

#### Scenario: Only one host was requested

- **WHEN** the user requests an update from a supported host without requesting other hosts
- **THEN** the agent updates only that host
- **AND** remote build access does not authorize remote installation, activation, or runtime updates

### Requirement: Verified official updates

The guidance SHALL use `omp update` for the official executable and the exact plugin-manager upgrade command defined by `publish-plugin-through-omp-plugin-manager` for personal behavior. It SHALL verify the installed result and applicable fresh-session smoke. An already-current result SHALL not require repository pin edits, publication, or Nix activation.

#### Scenario: Upstream updates successfully

- **WHEN** the official update command completes successfully
- **THEN** the agent continues to installed path/version checks and applicable fresh-session smoke in Tern
- **AND** it reports success only after those runtime completion checks pass

#### Scenario: The installation is already current

- **WHEN** the official update reports that the installation is current
- **THEN** the agent verifies the installed runtime
- **AND** it reports an already-current result rather than claiming a new version was installed

### Requirement: Explicit upstream operation authorization

The guidance SHALL continue through actions within the user's granted scope, preserving unrelated work. It SHALL obtain missing explicit authorization before publishing commits/tags, merging, activating hosts, updating another host, or changing credentials. The owner SHALL enter any required password or provider login through the appropriate terminal or browser, never an agent conversation. An update request SHALL not grant standing publication or fleet-update permission.

#### Scenario: A release requires publication

- **WHEN** a verified personal-plugin release requires publication that is not authorized
- **THEN** the agent identifies the concrete repository and operation requiring approval
- **AND** it does not claim the requested plugin upgrade is complete
- **AND** after approval it resumes the supported plugin-manager upgrade and runtime verification

#### Scenario: Activation requires unavailable administrator credentials

- **WHEN** package activation is needed but the owner cannot complete the required administrator interaction
- **THEN** the agent completes reachable safe work and reports the exact host command and current runtime state
- **AND** it does not request secret contents, bypass authentication, or claim the package generation is installed

### Requirement: Installed release completion evidence

An updated result SHALL identify the host/environment, actual official executable path and version, plugin-manager identity, installed release/path, and exercised checks. It SHALL require a fresh upstream OMP session in Tern and applicable personal-policy, commit-preview, Plannotator, language-server, and WSL browser checks. It SHALL distinguish the fresh process from still-running old sessions and record evidence with the change/session rather than current-state manuals.

#### Scenario: A new installation passes acceptance

- **WHEN** the installed executable/plugin pass direct checks and applicable fresh-session smoke
- **THEN** the agent reports observed versions/paths, exercised checks, and available recovery prerequisites
- **AND** a successful version command or publication alone is not complete acceptance

### Requirement: Official release recovery boundaries

The guidance SHALL report update failure or rejected acceptance honestly and inspect the error before retrying. Supported official-installer recovery SHALL select a recorded accepted binary release explicitly and repeat acceptance. It SHALL preserve mutable application and plugin-manager state, SHALL not invoke the removed source updater, and SHALL not claim Nix rollback changes the official executable or installed plugin. Plugin recovery SHALL use only the supported manager procedure established by the plugin publication change.

#### Scenario: Fresh-session smoke rejects the installed release

- **WHEN** fresh-session smoke fails and a recorded accepted official release is available
- **THEN** the agent reports failed acceptance and follows authorized official-installer recovery and repeat verification
- **AND** a recovered older runtime is reported as recovery, not a successful upgrade

#### Scenario: Recovery has no recorded accepted release

- **WHEN** the first official installation fails acceptance and no accepted release is recorded
- **THEN** the agent reports the failure and missing recovery prerequisite
- **AND** it does not delete state, invent a fallback, or claim rollback succeeded

## REMOVED Requirements

### Requirement: Failed preparation receives cause-specific repair

**Reason**: Source preparation and maintained patch replay are retired; upstream distribution owns executable preparation.
**Migration**: Remove the patch-repair/source-preparation runbook and skill; investigate official installer/updater failures from their real diagnostics without suppressing errors.

### Requirement: Herdr prerequisites use the command environment

**Reason**: Real-session acceptance moves to Tern; Herdr remains a secondary tool whose OMP integration the owner manages.
**Migration**: Run fresh real-session acceptance in Tern without marker fabrication, automatic pane control, or a Herdr prerequisite.

### Requirement: Discoverable repository update guidance

**Reason**: The authored wrapper-specific skill and its discovery/formatting contract are retired.
**Migration**: Use Discoverable upstream update guidance through AGENTS.md and README.

### Requirement: Current host and input discovery

**Reason**: Installed source-generation and patch-pin discovery no longer describe the runtime.
**Migration**: Use Installed upstream host discovery to distinguish executable/plugin releases from build-time check pins.

### Requirement: Routine updates reach a verified runtime

**Reason**: Patched-source preparation is replaced by the official executable and plugin manager.
**Migration**: Use Verified official updates and real-session acceptance without patch replay.

### Requirement: Authorization remains operation-specific

**Reason**: Patch publication and source selection are retired operations.
**Migration**: Preserve explicit credential/publication/host scope boundaries through Explicit upstream operation authorization.

### Requirement: Completion evidence comes from the selected runtime

**Reason**: Source commits, immutable plugin paths, verifier and Herdr evidence are obsolete.
**Migration**: Use Installed release completion evidence from actual upstream/plugin-manager paths and Tern sessions.

### Requirement: Failed acceptance preserves recovery boundaries

**Reason**: Source-generation recovery and previous source selectors are retired.
**Migration**: Use Official release recovery boundaries with recorded accepted releases and retained mutable state.
