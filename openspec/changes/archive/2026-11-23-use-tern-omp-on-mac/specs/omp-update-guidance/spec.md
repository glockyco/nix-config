## MODIFIED Requirements

### Requirement: Discoverable upstream update guidance

A fresh upstream OMP session in this repository SHALL find current ownership, Tern-managed installation and update operations, and the personal plugin's manager install/upgrade commands through AGENTS.md and README. The repository SHALL contain no wrapper-specific `omp-update` skill, patch-repair procedure, Herdr control prerequisite, or source-generation recovery runbook. Guidance SHALL not require previous conversation history.

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

The guidance SHALL determine the target host, official command path/version, plugin-manager installation identity/version, and requested scope before mutation. It SHALL default to the current host and SHALL NOT treat a Nix check-tool pin, previous session, or another host's evidence as the current runtime. Both hosts SHALL use Tern-managed OMP, and guidance SHALL identify the target host's executable.

#### Scenario: Check tools and installed plugin differ

- **WHEN** the reviewed build-time plugin/check input differs from the user's installed plugin release
- **THEN** the agent identifies their separate ownership
- **AND** it does not activate Nix to claim that the runtime plugin was upgraded

#### Scenario: Only one host was requested

- **WHEN** the user requests an update from a supported host without requesting other hosts
- **THEN** the agent updates only that host
- **AND** remote build access does not authorize remote installation, activation, or runtime updates

### Requirement: Verified official updates

The guidance SHALL use Tern's managed update flow for the executable and the exact plugin-manager upgrade command defined by `publish-plugin-through-omp-plugin-manager` for personal behavior. It SHALL verify the installed result and applicable fresh-session smoke. An already-current result SHALL not require repository pin edits, publication, or Nix activation.

#### Scenario: Upstream updates successfully

- **WHEN** the official update command completes successfully
- **THEN** the agent continues to installed path/version checks and applicable fresh-session smoke in Tern
- **AND** it reports success only after those runtime completion checks pass

#### Scenario: The installation is already current

- **WHEN** the official update reports that the installation is current
- **THEN** the agent verifies the installed runtime
- **AND** it reports an already-current result rather than claiming a new version was installed

### Requirement: Official release recovery boundaries

Guidance SHALL report update failure or rejected acceptance honestly and inspect errors before retrying. Recovery SHALL use only a supported Tern recovery operation and repeat acceptance. Guidance SHALL NOT invent a version-selection command or prescribe official-installer recovery when Tern has no supported recovery flow. It SHALL preserve mutable application/plugin-manager state, never invoke the removed source updater or claim Nix rollback changes the official executable/installed plugin. Plugin recovery SHALL use only the supported manager procedure established by the plugin publication change.

#### Scenario: Fresh-session smoke rejects the installed release

- **WHEN** fresh-session smoke fails and a recorded accepted official release is available
- **THEN** the agent reports failed acceptance and uses an authorized supported Tern recovery flow and repeats verification, or reports that no supported recovery operation is available
- **AND** a recovered older runtime is reported as recovery, not a successful upgrade

#### Scenario: Recovery has no recorded accepted release

- **WHEN** the first official installation fails acceptance and no accepted release is recorded
- **THEN** the agent reports the failure and missing recovery prerequisite
- **AND** it does not delete state, invent a fallback, or claim rollback succeeded
