## MODIFIED Requirements

### Requirement: Host-managed personal plugin updates

One shared fact SHALL declare the marketplace plugins both hosts keep current, each with its plugin identifier, its marketplace name and the marketplace's GitHub source. Each host SHALL run, hourly through its user-job layer, `omp plugin marketplace update <marketplace>` for every declared plugin, followed on success by `omp plugin upgrade --scope user <plugin>` for that plugin. A failed refresh or upgrade of one plugin SHALL NOT stop the other plugins, and the run SHALL exit nonzero when any plugin failed. Every command SHALL run without waiting for input and SHALL fail when it exceeds its time limit. New sessions SHALL load the installed releases while running sessions retain theirs. The job SHALL log its output and failures in a readable user file.

#### Scenario: A release is available

- **WHEN** the scheduled job refreshes a declared plugin's marketplace successfully
- **THEN** it upgrades that user-scoped plugin and logs the result
- **AND** running sessions are not restarted

#### Scenario: One marketplace fails

- **WHEN** the refresh of one declared marketplace fails
- **THEN** the job logs the failure, does not upgrade that plugin, still refreshes and upgrades the other declared plugins and exits nonzero

#### Scenario: A command waits for input

- **WHEN** a refresh would wait for input that nobody gives
- **THEN** the command fails within its time limit and the job logs the failure

### Requirement: Interactive Windows execution

Windows SHALL register an unelevated per-user task at logon and hourly using the user's interactive session, without opening a window. Marketplace EPERM failures SHALL receive bounded retries before that marketplace's refresh fails. Other errors SHALL fail that marketplace's refresh, and no upgrade of its plugin SHALL follow a failed refresh.

#### Scenario: Scheduled update runs while logged on

- **WHEN** the logon or hourly task runs in the logged-on user's session
- **THEN** it runs without opening a console or terminal window and without elevation

#### Scenario: Marketplace files are temporarily locked

- **WHEN** a marketplace refresh fails with EPERM
- **THEN** the run logs the failure and retries before upgrading that plugin

#### Scenario: Refresh cannot succeed

- **WHEN** refresh retries are exhausted or another refresh error occurs
- **THEN** the run logs the failure, does not upgrade that plugin and exits nonzero after handling the other declared plugins

### Requirement: Tern-owned Mac plugin updater

The Mac user job SHALL run every marketplace refresh and plugin upgrade using Tern's managed OMP executable independently of the login shell PATH. A failed refresh of a marketplace SHALL prevent the upgrade of its plugin. It SHALL not install, update or remove an OMP executable.

#### Scenario: An older standalone executable remains

- **WHEN** the Mac job runs while ~/.local/bin/omp still exists
- **THEN** every command uses $HOME/Library/Application Support/Tern/omp/bin/omp
- **AND** the standalone executable remains untouched

## ADDED Requirements

### Requirement: GitHub sign-in and marketplace sources

Before refreshing, the job SHALL check the GitHub sign-in that Git's HTTPS credential helper uses and SHALL log that `gh auth login` is needed when the sign-in is invalid. The job SHALL compare each declared marketplace's registered source with its declared GitHub source and SHALL log a mismatch together with the commands that register the declared source. The job SHALL NOT add, remove or re-register marketplaces.

#### Scenario: Expired GitHub sign-in

- **WHEN** the job runs while the GitHub sign-in is invalid
- **THEN** the log says that `gh auth login` is needed before any refresh result

#### Scenario: Marketplace registered over SSH

- **WHEN** a declared marketplace is registered with `git@github.com:glockyco/omp-booking.git` instead of `glockyco/omp-booking`
- **THEN** the job logs the mismatch with the commands that remove and add the marketplace with its declared source
- **AND** the registration stays unchanged
