# Spec Delta

## MODIFIED Requirements

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
