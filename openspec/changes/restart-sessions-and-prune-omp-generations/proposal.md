## Why

After `omp-dev-update` selects a new generation, every open OMP session keeps running the old one. Each session must be exited and resumed by hand, which is easy to forget with many open sessions. OMP's own `/restart` does not help: it re-executes the running generation's entry file, so it resumes on the old version. The updater also never removes generations. Korolev had accumulated about 37 GB of superseded and failed candidates, each also pinning a development environment in the Nix store.

## What Changes

- After a selection changes (a successful update or a rollback), `omp-dev-update` restarts idle OMP sessions that Herdr manages and that run a superseded generation. Each restart exits the session and resumes it through the wrapped `omp` command, so it starts on the selected generation. Busy, blocked, unclassified, or unmanaged sessions, and the session that invoked the updater, are left running and listed in the output. OMP itself is not patched.
- After the restarts, the updater removes every generation other than the current, the previous, and any that a running process still uses. This includes failed candidates of earlier runs.
- Add `omp-dev-update --prune`. It repeats the cleanup on demand, for example after the operator restarts sessions that were skipped. It performs no restart, network access, or selection change.
- Update the update procedure and README so that the manual session-restart and cleanup steps disappear.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `personal-omp-workstation`: selection changes restart idle Herdr-managed sessions, generation retention is bounded, and `--prune` is added.

## Impact

Affected files are `packages/omp-dev-update/src/omp_dev_update/__init__.py`, its tests, `packages/omp-dev-update/package.nix` (Herdr becomes a runtime input), `docs/operations/dependency-updates.md`, and README's update section. No OMP patch, Herdr configuration, scheduler, or new updater is added. Sessions outside Herdr keep today's behavior. Nix garbage collection stays with the host's existing policy.
