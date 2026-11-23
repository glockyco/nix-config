## ADDED Requirements

### Requirement: Tern-owned Mac plugin updater

The Mac user job SHALL run both marketplace refresh and personal-plugin upgrade using Tern's managed OMP executable independently of the login shell PATH. Failure of marketplace refresh SHALL prevent upgrade. It SHALL not install, update or remove an OMP executable.

#### Scenario: An older standalone executable remains

- **WHEN** the Mac job runs while ~/.local/bin/omp still exists
- **THEN** both commands use $HOME/Library/Application Support/Tern/omp/bin/omp
- **AND** the standalone executable remains untouched
