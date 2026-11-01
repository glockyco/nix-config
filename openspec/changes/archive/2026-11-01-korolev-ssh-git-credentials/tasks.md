# Tasks

## 1. Configure encrypted Git storage

- [x] 1.1 Select GCM current-user DPAPI storage and assert the effective setting in the native chezmoi fixture.
- [x] 1.2 Update the remote access runbook with Git authentication and the independent OMP mitigation boundary.

## 2. Verify and deliver

- [x] 2.1 Run Windows checks, engine dry run and chezmoi apply from the PR branch on Korolev.
- [x] 2.2 Transfer existing credentials in memory through GCM and verify a real vault commit push over SSH plus desktop Git access.
- [x] 2.3 Validate and archive the change, merge the green PR and watch main checks.
