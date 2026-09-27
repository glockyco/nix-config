## Scheduling — 2026-09-26

The owner scheduled this change after plan review. It runs at position 4, after `separate-platform-baseline-from-roles` and its Mac gates.

## Why

The Darwin host has two Python programs that no package build tests. `modules/home/darwin/fastmail.nix:12-17` wraps the path to `fastmail.py`. `modules/home/darwin/apple-terminal.nix:16-18` runs `apple-terminal.py` by path. The Fastmail client already has `main()` and catches `JmapError` (`modules/home/darwin/fastmail.py:444-503`). The font program reads `sys.argv[1]` on import and executes at module scope (`modules/home/darwin/apple-terminal.py:9,56-94`).

Several Darwin activation blocks write unchanged state. `modules/home/darwin/neo2.nix:19-26` recopies a keyboard layout and touches its directory. `modules/home/darwin/karabiner.nix:55-58` reinstalls its configuration. `modules/home/darwin/default-apps.nix:375-383` recopies and registers `FileTypes.app`, while its binding writes ignore errors (`modules/home/darwin/default-apps.nix:311-345`). `modules/home/darwin/keyboard-shortcuts.nix:68-77` creates and edits a temporary file outside Home Manager's `run` helper. `modules/roles/darwin/desktop/power.nix:9-12` always runs `pmset`. `modules/roles/darwin/desktop/rosetta.nix:5-10` probes a daemon rather than execution and ignores installation failure.

`modules/home/darwin/screenshots.nix:15-17` already uses `run` for an idempotent `mkdir -p`, so it needs no new program. `modules/roles/darwin/air-client/network-shares.nix` manages the temporary Air's mount agent, not activation; the Air role owns it. The PostgreSQL `install -d` step remains: the user agent needs `/var/lib/postgresql/17`, and that step is idempotent (`modules/roles/darwin/postgresql/postgresql.nix:35-40`).

## What Changes

- Package `fastmail`, `apple-terminal-font`, and `symbolic-hotkeys` under `packages/<name>/` with import-safe `main(argv: Sequence[str] | None = None) -> int` entry points. Each owns `argparse`, parses `sys.argv[1:]` when `argv` is `None`, and exits its console script with the return value. Give Fastmail ZIP, gzip, XML, malformed-report, and command tests. Test font preservation and hotkey domain merges against `defaults` doubles.
- Package `neo-keyboard-layout-install`, `karabiner-configuration`, `default-applications`, `power-settings`, and `rosetta` as tested shell programs. Compare before writing and report failures, except for the documented LaunchServices `-50` result.
- Replace the symbolic-hotkey description attribute set with identifiers and nearby binding comments. Put its complete invocation behind Home Manager's `run` helper.
- Put every package in `packages/<name>/package.nix`, with `tests.nix` beside it. Use the generated overlay from `key-fleet-by-host` and register the command tests through `flake-modules/checks.nix`.
- Update the affected module comments, README activation guidance, and relevant operations documentation as part of this change.

## Capabilities

### New Capabilities

- `darwin-host-activation`: packaged activation concerns compare before writes, fail on unexpected errors, and write nothing in a Home Manager dry run.

### Modified Capabilities

- `repository-quality-gates`: repository-owned user and activation programs have packages and observable behavior checks.

## Impact

The change replaces the two Python files and activation blocks in `modules/home/darwin/{fastmail,apple-terminal,neo2,karabiner,default-apps,keyboard-shortcuts}.nix`. It also updates the power and Rosetta declarations after the Darwin role cutover. `separate-platform-baseline-from-roles` placed their declarations in `modules/roles/darwin/desktop/{power,rosetta}.nix`; it placed PostgreSQL in `modules/roles/darwin/postgresql/postgresql.nix`. The package overlay is generated in `flake-modules/packages.nix`; command checks are registered in `flake-modules/checks.nix`.

The packaged commands compare state before each write. Home Manager places its five activation programs under `run` for dry-run protection. Command checks prove unchanged state causes no write and unexpected binding, preference, or Rosetta errors fail. PostgreSQL keeps its existing cluster and idempotent directory preparation. The Mac builds the Darwin-only checks; CI builds checks on both platforms. Fastmail also builds on Linux.
