## Purpose

Provide discoverable repository-local guidance that enables an agent to complete authorized personal OMP updates, including patch repair, runtime verification, and safe recovery.

## ADDED Requirements

### Requirement: Discoverable repository update guidance

A fresh wrapped OMP session in this repository SHALL discover the `omp-update` skill without manual skill installation or global configuration changes. The skill SHALL identify ordinary update requests and patch-conflict recovery as applicable tasks. It SHALL direct the agent to current repository procedures rather than previous conversation history.

#### Scenario: Request an update in a fresh session

- **WHEN** the user asks a fresh wrapped session in this repository to update OMP
- **THEN** the agent can discover and read `omp-update` and its supporting procedures
- **AND** those procedures are sufficient to determine the next action without a previous session transcript

### Requirement: Current host and input discovery

The guidance SHALL determine the target host, installed command ownership, selected generation, declared patch inputs, and requested operation scope before mutation. It SHALL default to the current supported host. It SHALL distinguish installed updater inputs from repository pins and SHALL NOT treat historical versions or another host's evidence as current local facts.

#### Scenario: Repository pins are newer than installed pins

- **WHEN** reviewed repository pins differ from the installed updater inputs
- **THEN** the agent identifies the mismatch before retrying the old patch range
- **AND** it follows the applicable configuration gates and authorized activation before using the refreshed inputs

#### Scenario: Only one host was requested

- **WHEN** the user requests an update from a supported host without requesting other hosts
- **THEN** the agent updates only that host
- **AND** remote build or patch-access verification does not authorize remote activation or runtime selection

### Requirement: Routine updates reach a verified runtime

The guidance SHALL use `omp-dev-update` for runtime preparation and selection. It SHALL continue through post-selection verification when preparation succeeds. It SHALL preserve an unchanged-input result as a valid no-op and SHALL NOT require a patch refresh, pin edit, publication, or activation when none is needed.

#### Scenario: Existing patches apply to a new release

- **WHEN** the updater prepares and selects the stable release successfully with existing pins
- **THEN** the agent continues to the applicable release smoke
- **AND** it reports success only after the runtime completion checks pass

#### Scenario: The selected inputs are already current

- **WHEN** the updater reports unchanged inputs
- **THEN** the agent verifies the selected runtime
- **AND** it reports an already-current result rather than claiming a new generation was installed

### Requirement: Failed preparation receives cause-specific repair

The guidance SHALL inspect the reported phase and failed candidate without editing an active generation or destroying diagnostic evidence. Patch conflicts SHALL be repaired in a separate maintained worktree. The agent SHALL review upstream changes, preserve each intended patch behavior, verify any upstream replacement, and review the complete refreshed range before publication. Non-conflict failures SHALL be investigated according to their cause, without bypassing checks or using an executable fallback.

#### Scenario: Upstream overlaps a maintained patch

- **WHEN** patch replay fails because upstream changed the same code
- **THEN** the agent refreshes the maintained series against the resolved stable release in a separate worktree
- **AND** it verifies the affected behavior and complete range, including release-note placement
- **AND** it does not silently discard either side or modify the failed candidate to manufacture a successful update

#### Scenario: Preparation fails after replay

- **WHEN** dependencies, native compilation, package checks, or launch verification fail
- **THEN** the agent investigates that failure rather than treating it as a merge conflict
- **AND** any repair is verified before another production preparation attempt
- **AND** unavailable prerequisites are reported with the failed phase and unchanged selection

### Requirement: Authorization remains operation-specific

The guidance SHALL continue through all actions within the user's granted scope. It SHALL obtain missing explicit authorization before publishing commits or tags and SHALL distinguish patch publication from configuration publication. It SHALL respect host activation and runtime-selection boundaries, preserve unrelated work, and report credential or authorization blockers precisely. Skill invocation SHALL NOT grant standing publication, force-push, credential-change, or fleet-update permission.

#### Scenario: Patch repair requires publication

- **WHEN** a verified patch refresh must become independently fetchable and publication is not authorized
- **THEN** the agent requests authorization for the specific fork branch and operation
- **AND** it does not claim the OMP update is complete
- **AND** after approval it resumes publication, pin integration, applicable activation, runtime preparation, and verification without stopping at an intermediate artifact

#### Scenario: Activation requires unavailable administrator credentials

- **WHEN** activation is needed but the agent cannot perform the authorized administrator operation
- **THEN** it completes reachable safe work and reports the exact operator command and current runtime state
- **AND** it does not request secret contents, bypass authentication, or claim the new pins are installed

### Requirement: Completion evidence comes from the selected runtime

An updated result SHALL identify the host, selected stable release, upstream commit, patch base and tip, resulting runtime commit, and observed verification results. It SHALL require `verify-personal-omp`, a fresh session through the supported wrapper and Herdr integration, and the applicable documented release smoke. It SHALL distinguish the new session from any still-running old session. Evidence SHALL remain with the relevant change or session, not as hard-coded current facts in the skill.

#### Scenario: A new generation passes acceptance

- **WHEN** the selected generation passes the verifier and applicable fresh-session smoke
- **THEN** the agent reports the selected identities, immutable plugin, current Herdr integration, exercised checks, and recovery generation availability
- **AND** publication of patches or a successful version command alone is not presented as complete acceptance

### Requirement: Failed acceptance preserves recovery boundaries

The guidance SHALL distinguish preparation failure from rejection after promotion. It SHALL use `omp-dev-update --rollback` for authorized source-version recovery when a previous verified generation exists. It SHALL retain generations and mutable application state and SHALL NOT use Nix rollback or official installers as substitutes for OMP source recovery.

#### Scenario: Fresh-session smoke rejects the selected release

- **WHEN** post-selection smoke fails and a previous verified generation is available
- **THEN** the agent reports failed acceptance and follows authorized source rollback and repeat verification
- **AND** a recovered old runtime is reported as recovery, not a successful upgrade

#### Scenario: Recovery has no previous generation

- **WHEN** the first selected generation fails acceptance and no previous generation exists
- **THEN** the agent reports the failure and missing recovery prerequisite
- **AND** it does not delete state, invent a fallback, or claim rollback succeeded
