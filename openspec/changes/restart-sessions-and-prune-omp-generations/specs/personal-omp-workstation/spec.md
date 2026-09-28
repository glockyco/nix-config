## ADDED Requirements

### Requirement: Idle sessions follow a selection change

After `omp-dev-update` changes the selected generation through an update or a rollback, it SHALL restart each OMP session that the local Herdr server manages, that Herdr reports as idle, and whose process runs a generation other than the selected one. A restart SHALL end the session through OMP's normal exit and SHALL resume the same session file in the same pane through the wrapped `omp` command, so the resumed session runs the selected generation. The updater SHALL restart only a session whose input editor it confirms to be empty and that was launched without operator arguments beyond the wrapper's own, other than one `--resume` or `--continue` selection of its session. It SHALL NOT restart a session that Herdr reports as working, blocked, or unknown, the session that invoked the updater, or a session Herdr does not manage. A restart failure SHALL NOT change the selection or the command's exit status. The updater SHALL NOT modify OMP.

#### Scenario: Restart idle sessions after an update

- **WHEN** an update selects a new generation while idle Herdr-managed sessions with empty editors run the previous one
- **THEN** each of those sessions exits and resumes the same session file in its pane
- **AND** each resumed process runs the selected generation

#### Scenario: Leave busy sessions running

- **WHEN** a superseded session is working, blocked on a question or approval, or unclassified
- **THEN** the updater leaves it running on its generation and reports it with that state

#### Scenario: Preserve an unsent draft

- **WHEN** a superseded idle session holds unsent text in its editor, or the editor cannot be located on screen
- **THEN** the updater sends nothing to that session and reports it

#### Scenario: Preserve custom launch arguments

- **WHEN** a superseded idle session was launched with arguments beyond the wrapper's plugin arguments and one session selection
- **THEN** the updater does not restart it and reports it

#### Scenario: Leave the invoking session running

- **WHEN** the operator or an agent runs the updater from inside a Herdr-managed OMP session
- **THEN** that session is not restarted and is reported as the invoking session

#### Scenario: Herdr is unavailable

- **WHEN** no local Herdr server is reachable
- **THEN** the selection completes and the report states that Herdr was unavailable

#### Scenario: Unchanged update

- **WHEN** the update reports the current generation without a new selection
- **THEN** no session is restarted and no generation is removed

### Requirement: Bounded generation retention

After a selection change and its session restarts, and on `omp-dev-update --prune`, the updater SHALL remove every generation directory other than the current generation, the previous generation, and any generation that a running process names in its arguments. Removal SHALL include failed candidates of earlier runs and their Git worktree registrations. It SHALL NOT change the selection, touch the package cache or OMP application state, or run Nix garbage collection. `--prune` SHALL require no network access, SHALL hold the update lock, and SHALL restart no session.

#### Scenario: Remove superseded generations after an update

- **WHEN** an update selects a new generation and no process uses an older, non-previous generation
- **THEN** only the current and previous generations remain

#### Scenario: Keep a generation in use

- **WHEN** a running process still uses a superseded generation
- **THEN** that generation remains and is reported with its process count

#### Scenario: Prune on demand

- **WHEN** the operator restarts skipped sessions and runs `omp-dev-update --prune`
- **THEN** the generations those sessions used are removed
- **AND** the selection and rollback target are unchanged

#### Scenario: Failed update leaves evidence

- **WHEN** an update fails
- **THEN** its candidate remains for inspection until the next successful cleanup

### Requirement: Machine-readable update report

On success, `omp-dev-update`, `--rollback`, and `--prune` SHALL print one JSON object to standard output. For an update or rollback, the object SHALL contain the selected generation's metadata fields. When a selection changed, and for `--prune`, it SHALL also contain `sessions` and `generations` members. `sessions` SHALL state whether Herdr was available, list each restarted pane with its session file, and list each superseded session left running with its pane, session file, generation, and a reason from a fixed set. `generations` SHALL list removed generations and the retained current, previous, and in-use generations with their process counts. `--status` output SHALL remain the metadata alone. A human-readable summary SHALL go to standard error.

#### Scenario: An agent relays skipped sessions

- **WHEN** an agent runs `omp-dev-update` and some sessions could not be restarted
- **THEN** the JSON report names each such pane and reason
- **AND** the agent can tell the operator which sessions still need a manual restart, including its own
