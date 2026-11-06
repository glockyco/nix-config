# Personal Plugin Updates Specification

## Purpose

Keep the personal OMP plugin current on supported workstations without replacing plugins in running sessions.

## Requirements

### Requirement: Host-managed personal plugin updates

Each host SHALL run `omp plugin marketplace update glockyco` followed on success by `omp plugin upgrade --scope user personal@glockyco` hourly through its user-job layer. New sessions SHALL load the installed release while running sessions retain theirs. The job SHALL log its output and failures in a readable user file.

#### Scenario: A release is available

- **WHEN** the scheduled job refreshes the marketplace successfully
- **THEN** it upgrades only the user-scoped personal plugin and logs the result
- **AND** running sessions are not restarted

### Requirement: Interactive Windows execution

Windows SHALL register an unelevated per-user task at logon and hourly using the user's interactive session, without opening a window. Marketplace EPERM failures SHALL receive bounded retries before the run fails. Other errors SHALL stop the run, and no upgrade SHALL follow a failed refresh.

#### Scenario: Scheduled update runs while logged on

- **WHEN** the logon or hourly task runs in the logged-on user's session
- **THEN** it runs without opening a console or terminal window and without elevation

#### Scenario: Marketplace files are temporarily locked

- **WHEN** the marketplace refresh fails with EPERM
- **THEN** the run logs the failure and retries before upgrading

#### Scenario: Refresh cannot succeed

- **WHEN** refresh retries are exhausted or another refresh error occurs
- **THEN** the run logs failure, exits nonzero and does not upgrade
