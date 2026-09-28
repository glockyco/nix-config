## ADDED Requirements

### Requirement: Idle sessions follow a selection change

After `omp-dev-update` changes the selected generation through an update or a rollback, it SHALL restart each OMP session that the local Herdr server manages, that Herdr reports as idle, and whose process runs a generation other than the selected one. A restart SHALL end the session through OMP's normal exit and SHALL resume the same session in the same pane through the wrapped `omp` command, so the resumed session runs the selected generation. The updater SHALL NOT restart a session that Herdr reports as working, blocked, or unknown, the session that invoked the updater, or a session Herdr does not manage. It SHALL list every superseded session it left running. A restart failure SHALL NOT change the selection or the update's exit status. The updater SHALL NOT modify OMP.

#### Scenario: Restart idle sessions after an update

- **WHEN** an update selects a new generation while idle Herdr-managed sessions run the previous one
- **THEN** each of those sessions exits and resumes the same session in its pane
- **AND** each resumed process runs the selected generation

#### Scenario: Leave busy sessions running

- **WHEN** a superseded session is working, blocked on a question or approval, or unclassified
- **THEN** the updater leaves it running on its generation
- **AND** the output names its pane and state

#### Scenario: Leave the invoking session running

- **WHEN** the operator runs the updater from inside a Herdr-managed OMP session
- **THEN** that session is not restarted and is listed for manual restart

#### Scenario: Herdr is unavailable

- **WHEN** no local Herdr server is reachable
- **THEN** the selection completes as before and the output states that no session was restarted

#### Scenario: Unchanged update

- **WHEN** the update reports the current generation without a new selection
- **THEN** no session is restarted

### Requirement: Bounded generation retention

After a selection change and its session restarts, and on `omp-dev-update --prune`, the updater SHALL remove every generation directory other than the current generation, the previous generation, and any generation whose files a running process uses. Removal SHALL include failed candidates of earlier runs and their Git worktree registrations. It SHALL NOT change the selection, touch the package cache or OMP application state, or run Nix garbage collection. `--prune` SHALL require no network access and SHALL hold the update lock.

#### Scenario: Remove superseded generations after an update

- **WHEN** an update selects a new generation and no process uses an older, non-previous generation
- **THEN** only the current and previous generations remain

#### Scenario: Keep a generation in use

- **WHEN** a running process still uses a superseded generation
- **THEN** that generation remains until a later cleanup finds it unused

#### Scenario: Prune on demand

- **WHEN** the operator restarts skipped sessions and runs `omp-dev-update --prune`
- **THEN** the generations those sessions used are removed
- **AND** the selection and rollback target are unchanged

#### Scenario: Failed update leaves evidence

- **WHEN** an update fails
- **THEN** its candidate remains for inspection until the next successful cleanup
