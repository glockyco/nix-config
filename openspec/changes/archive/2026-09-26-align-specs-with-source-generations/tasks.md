## Scheduling — 2026-09-26

The owner scheduled this change after plan review. It is change 0, has no predecessor, and precedes `key-fleet-by-host`.

## 1. Validate the Contract

- [x] 1.1 Run `openspec validate align-specs-with-source-generations --strict`; retain its passing output as proof that every delta and scenario is valid.

## 2. Sync and Archive

- [x] 2.1 After strict validation, sync the delta requirements into `openspec/specs/`; inspect the resulting capability files to prove every moved requirement has one owner and every removed requirement is gone from `personal-omp-workstation`.
- [x] 2.2 Search `openspec/specs/` for `Homebrew`, `official prebuilt`, `ompRuntime`, and `installCommand`; record that no current-contract hit remains after sync.
- [x] 2.3 Mark completed tasks and archive the change; verify that the archived change contains no unchecked task and that its synced main specs validate strictly.
