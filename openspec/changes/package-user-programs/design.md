## Context

See `proposal.md` for the motivation and the two delta specs for the contract. The facts that shape the approach:

- The deferred implementation plan assumes that every earlier change in the sequence is archived before work starts. This assumed baseline does not authorize implementation or make this change a prerequisite for the near-term OMP and Tailscale work. Packages reach modules as `pkgs.<name>` from a hand-written `overlays.default` list in `flake-modules/packages.nix`, where the attribute equals the file basename under `packages/`. `flake-modules/checks.nix` calls `pkgs.callPackage ./packages/<x>-tests.nix { }` for each program test, and the test file takes its subject by its overlay attribute name. Platform gating of a package or check derives from `lib.meta.availableOn`. The three system-scope modules live at `modules/roles/darwin/{power,rosetta,postgresql}/default.nix`. The user-scope modules stay in `modules/home/darwin/`.
- Home Manager's `run` helper prints its arguments and executes nothing when `DRY_RUN` is set (`lib/bash/home-manager.sh:109-127` in the pinned revision). `DRY_RUN_CMD` is deprecated (`modules/lib-bash/activation-init.sh:151-153`). The `home.activation` option text asks every block to respect `DRY_RUN` (`modules/home-environment.nix:474-476`). `home.file` always links the target to the store (`modules/files.nix:423`); it has no copy mode.
- nix-darwin runs every activation script as `root` (`modules/system/activation-scripts.nix:110`) and offers no dry run: `darwin-rebuild --dry-run` passes the flag to `nix build` alone and exits before activation (`pkgs/nix-tools/darwin-rebuild.sh:59,213`).
- The nix-darwin PostgreSQL agent runs `initdb` when `PG_VERSION` is absent and never creates the data directory (`modules/services/postgresql/default.nix:340-352`), although the `dataDir` option text says the default directory is created automatically (`default.nix:67-77`). The agent script interpolates `dataDir` unquoted, so the path must contain no space.
- `duti -s` exits `2` for every LaunchServices failure and prints `failed to set <app> as handler for <type> (error <n>)` on standard error (`handler.c:75-79`, `handler.c:502`, and `duti.c:94-101` at the pinned revision `fe3d3dc`). The exit status cannot distinguish the documented `-50` case; the message can.
- `packages/duti` in the pinned Nixpkgs declares `meta.platforms = lib.platforms.darwin`, so a program with `duti` in `runtimeInputs` cannot evaluate on Linux.
- Home Manager activation does not put `/usr/bin` on `PATH` (`apple-terminal.py:53`). The sibling programs take each external executable from an environment variable that defaults to the real one (`packages/air-batch-check.nix:20-22`), and their tests point those variables at doubles that record calls (`packages/air-batch-check-tests.nix:94-99`).
- The pinned Nixpkgs provides `python3Packages.buildPythonApplication` with `pyproject = true` and `unittestCheckHook`, which runs `python -m unittest discover` in `checkPhase`.

## Goals / Non-Goals

**Goals:**

- One package per program, one test per package, and one invocation shape from modules.
- A second activation of the same generation is observably a no-op for every concern this change owns.
- An unexpected failure stops activation instead of printing a warning.
- The Python programs are importable and unit-tested.

**Non-Goals:**

- Changing what any concern declares: the layout bundle, the Karabiner rules, the file-type list, the shortcut identifiers, the font name, the power values, and the PostgreSQL settings keep their values.
- Reconciling Herdr in `modules/home/omp.nix`. That block already reads state before it writes, and `personal-omp-workstation` owns it.
- The `mkdir -p` in `modules/home/darwin/screenshots.nix`. It is idempotent and needs no program.
- Removing the remaining `|| true` reads in `default-applications`. A `duti -x` or `duti -d` read exits non-zero for a type with no handler, and that is an answer, not an error.
- Moving the Windows check to `packages/`. `derive-windows-check-from-declaration` reuses the Python shape this change sets.

## Decisions

### 1. Python programs are `buildPythonApplication` packages with stdlib tests

Each Python program lives in `packages/<name>/` with `pyproject.toml`, `src/<module>/__init__.py`, a `main()` that owns `argparse`, and `tests/` written with `unittest`. `packages/<name>.nix` builds it with `python3Packages.buildPythonApplication`, `pyproject = true`, `build-system = [ setuptools ]`, `nativeCheckInputs = [ unittestCheckHook ]`, and `meta = { description; mainProgram; platforms; }`. The package build is the unit test; a failing test fails the build and therefore every check that depends on it.

`apple-terminal-font` gets the same treatment as `fastmail`. Its module-level statements move into `main()`, and the font blob functions take and return values, so a test can call `archived_font` and `font_name` on a round trip without a `defaults` binary.

**Alternative:** `writers.writePython3Bin`. Rejected because it runs `flake8` alone, has no test phase, gives the program no importable module, and cannot carry the fixtures.

**Alternative:** `pytestCheckHook`. Rejected because the programs use only the standard library, `unittest` covers fixture-driven tests, and `darwin-dependency-builds` asks for the smallest test-only closure on Darwin.

### 2. One `writeShellApplication` per activation concern, with executable seams

`neo-keyboard-layout-install`, `karabiner-configuration`, `default-applications`, `power-settings`, and `rosetta` are `writeShellApplication` packages with `meta` and `runtimeInputs` passed as direct arguments. Each macOS executable that the program calls comes from an environment variable named `<PROGRAM>_<TOOL>` that defaults to the absolute path, for example `POWER_SETTINGS_PMSET=/usr/bin/pmset` and `DEFAULT_APPLICATIONS_LSREGISTER`. The tests set those variables to doubles that record their calls.

Every activation program declares `meta.platforms = lib.platforms.darwin`. Its purpose is Darwin state, `duti` forces that declaration for one of them anyway, and `nix run` of such a program on Linux would fail at the first absolute path. The consequence is that these tests build on the Darwin continuous-integration leg, on the Mac, and from korolev through the remote builder. `fastmail` declares `lib.platforms.all`, because it is a JMAP client with no platform dependency.

**Alternative:** `lib.platforms.unix` on the activation programs so that their tests run on the Linux leg. Rejected because it declares a platform on which the program cannot run, and `duti` makes the declaration false for `default-applications` regardless.

### 3. Modules invoke programs through `run` and `lib.getExe`

Each Home Manager block becomes `run ${lib.getExe pkgs.<name>} <arguments>`, which is the shape `modules/home/omp.nix:30` already uses. Under `DRY_RUN`, Home Manager prints the command and executes nothing, which satisfies the dry-run requirement for every concern at once and moves the `mktemp`, `defaults export`, and `plutil` calls of `keyboard-shortcuts.nix` behind the helper.

The programs have no dry-run flag of their own. Home Manager provides that mode, `DRY_RUN_CMD` is deprecated, and a second mode inside each program is code that only a second test would exercise.

The system-scope programs run from `system.activationScripts.extraActivation.text` as `root` with no helper, because nix-darwin has none. Their idempotence is the guard against repeated writes.

### 4. Each concern compares against the store before it writes

| Program                       | Reads                                                                                                  | Writes only when                                                               |
| ----------------------------- | ------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------ |
| `neo-keyboard-layout-install` | `diff -rq` of the store bundle and the installed bundle                                                | the bundle is absent or differs; then `touch` the directory                    |
| `karabiner-configuration`     | `cmp -s` of the generated file and `~/.config/karabiner/karabiner.json`                                | the file is absent or differs; the directory when absent                       |
| `default-applications`        | `diff -rq` of the store bundle and `~/Applications/FileTypes.app`; `duti -d` and `duti -x` per binding | the bundle differs, then `lsregister -f` once; a binding whose handler differs |
| `symbolic-hotkeys`            | `defaults export com.apple.symbolichotkeys -` parsed with `plistlib`                                   | at least one declared identifier is enabled or absent                          |
| `apple-terminal-font`         | `defaults export com.apple.Terminal -` parsed with `plistlib`                                          | a profile Terminal opens with names another font                               |
| `power-settings`              | `pmset -g custom` parsed per power source                                                              | a declared value differs for that power source                                 |
| `rosetta`                     | `arch -arch x86_64 /usr/bin/true`                                                                      | the probe fails                                                                |

`diff -rq` compares content and ignores the mode difference between the read-only store and the writable copy. The `touch` on the layout directory stays inside the changed branch, because the mtime bump is what makes macOS recompile the layouts (`neo2.nix:16-17`).

The `symbolic-hotkeys` program uses `plistlib` instead of `plutil` for the same reason `apple-terminal-font` does: `defaults export` writes an XML property list, `plistlib` reads and writes it, and the program then needs no macOS-only editor and can run against a `defaults` double. Both programs compare the parsed structure and skip the import when nothing changes, so an import never runs on a steady state. Each program reports `current` or the names it changed on standard error.

### 5. Karabiner keeps a compared copy, not `home.file`

`home.file` links the target into the store and has no copy mode. Karabiner-Elements rewrites `karabiner.json` in place and sets the directory to `0700` (`karabiner.nix:51-53`), so a store link breaks on the first save. `force` would replace the file with a link on every generation, and `onChange` fires on a change between generations, not on drift on the host. A `cmp -s` against the generated file is the honest check and the smallest one.

### 6. `default-applications` takes a declaration file and tolerates one documented failure

The module renders one JSON document with `pkgs.formats.json`: the store path of the bundle, the list of `{ app, uti }` bindings, the list of `{ app, extension, uti }` bindings, and the list of `{ app, scheme }` bindings. The program takes `--declaration <file>` and reads it with `jq`. The Nix module keeps the file-type table, the measured rationale, and the rendering of `FileTypes.app`; the program keeps the reads, the writes, and the error policy.

A `duti -s` failure is fatal unless its standard error contains `(error -50)`, which is the documented result for an extension that macOS resolves to a dynamic identifier (`default-apps.nix:18-21`). The program prints the type it skipped. A failed `lsregister -f` is fatal, because a bundle that LaunchServices did not register declares nothing.

**Alternative:** keep `|| true` on the writes and log. Rejected because a wrong bundle identifier then passes silently, which is the audited defect.

### 7. `keyboard-shortcuts.nix` declares a list of identifiers with comments

The `disabled` attribute set (`keyboard-shortcuts.nix:9-58`) maps each identifier to a description that nothing reads. The module becomes a list of identifier strings, each followed by a comment that records the binding, and passes the list as arguments to `symbolic-hotkeys`. Comments are the place for documentation that no code consumes.

**Alternative:** keep the attribute set and pass `attrNames`. Rejected because the values remain data that the module system evaluates and nothing uses.

### 8. Rosetta is probed by running an `x86_64` executable, and a failed installation is fatal

`pgrep oahd` reports a daemon, not the ability to run an `x86_64` binary. `arch -arch x86_64 /usr/bin/true` exits zero when Rosetta is installed and fails otherwise. `softwareupdate --install-rosetta --agree-to-license` runs only after the probe fails, and its failure fails activation, because CrossOver depends on Rosetta (`rosetta.nix:2`) and a generation that skips a declared dependency should not become current.

### 9. Power settings are compared per power source

`pmset -g custom` prints one section per power source with one `key value` line per setting. The program parses the `AC Power` and `Battery Power` sections, compares `sleep` and `displaysleep` with the declared values, and runs `pmset -c` or `pmset -b` only for a source whose values differ. The declared values move from the shell string into program arguments (`--ac sleep=0,displaysleep=10 --battery sleep=1,displaysleep=15`), so the module states the declaration and the program owns the comparison.

### 10. The PostgreSQL cluster moves under the primary user's home

`services.postgresql.dataDir` becomes `${config.system.primaryUserHome}/.local/share/postgresql/${config.services.postgresql.package.psqlSchema}`. The user agent then creates its own data directory, because `initdb` creates a missing data directory below a parent the user can write, and the root activation step disappears. Task 6.2 proves that on the Mac with a temporary path before the cluster moves. The path contains no space because the nix-darwin agent script interpolates it unquoted. The version segment stays, because a cluster opens only under the major version that wrote it (`postgresql.nix:7-10`).

The existing cluster moves once by hand: stop the agent, move the directory with ownership preserved, activate, and confirm that the agent serves the moved cluster. The old directory stays until the confirmation.

**Alternative:** keep `/var/lib/postgresql/17` and guard `install -d` with `test -d`. Rejected because root activation still owns a directory that belongs to a user agent, and the guard hides the ownership mistake that the audit named.

### 11. Tests run the built program against doubles and assert calls

Each `packages/<x>-tests.nix` follows `air-batch-check-tests.nix`: a `runCommand` writes doubles for every seam, points the seam variables at them, runs the program under each state, and asserts exit status, standard error, and the recorded calls.

- `neo-keyboard-layout-install-tests.nix`: absent bundle installs and touches; identical bundle changes no mtime; a differing file replaces the bundle.
- `karabiner-configuration-tests.nix`: absent file installs with `0600` in a `0700` directory; identical file leaves the mtime; differing file replaces.
- `default-applications-tests.nix`: `duti` double answers `-d`, `-x`, and `-s` from a fixture handler table and records writes; `lsregister` double records calls. Cases: everything current writes nothing; changed bundle registers once; differing handler binds once; `(error -50)` continues; another error fails with the type in the message.
- `symbolic-hotkeys-tests.nix`: `defaults` double serves a fixture domain and records `import` with its standard input; cases: all disabled imports nothing; one enabled imports once with only that entry changed; export failure exits non-zero.
- `apple-terminal-font-tests.nix`: `defaults` double serves a fixture domain with two profiles; cases: font current imports nothing; font differs imports once with the size preserved; profile absent imports nothing.
- `power-settings-tests.nix`: `pmset` double prints a fixture `-g custom` captured from the Mac and records writes; cases: current writes nothing; battery differs writes `-b` only.
- `rosetta-tests.nix`: `arch` double succeeds or fails; `softwareupdate` double records calls and can fail; cases: present calls nothing; absent installs once; installation failure exits non-zero.
- `fastmail-tests.nix`: the built program with no token file exits `1` and names the option on standard error. The DMARC decoder, the archive handling, and the report shape are unit tests with ZIP, gzip, XML, malformed, and non-`feedback` fixtures inside the package.

### 12. Acceptance gate: live proof on the Mac plus the deterministic tests

The behavior change is proven where the surface is real:

1. Record `stat -f '%N %m'` for `~/Library/Keyboard Layouts`, its bundle, `~/.config/karabiner/karabiner.json`, and `~/Applications/FileTypes.app` before and after a second `darwin-switch` of the same generation, and require equality.
1. Require the activation output to report every concern as current on that second switch, and require no `lsregister`, `pmset`, or `defaults import` line in it.
1. Build the user's `home.activationPackage` and snapshot every path these concerns own. Run `DRY_RUN=1 result/activate`, require that the output names each program, and confirm that the snapshots are unchanged.
1. Confirm `pmset -g custom` and `arch -arch x86_64 /usr/bin/true` before and after.
1. Confirm that the PostgreSQL agent serves the moved cluster.

## Risks / Trade-offs

- \[The `-50` detection depends on `duti`'s message text\] → The text is asserted in the test against the pinned revision, and a `duti` bump that changes it fails the test rather than activation.
- [Terminal.app rewrites its preferences on quit and can undo an import] → The program keeps the existing warning when Terminal is running, and the proof step quits Terminal first.
- \[`cfprefsd` caches a domain, so an import can lag a following export\] → Both `defaults` programs compare the parsed structure, so a lagging read costs one extra import and never a wrong one.
- [Moving the PostgreSQL cluster is a one-time data operation on the Mac] → The migration keeps the old directory until the agent serves the moved cluster, and `pg_dumpall` runs before the move.
- [Activation program tests do not build on the Linux leg] → They build on the Darwin leg, on the Mac, and from korolev through the remote builder, and the Python unit tests fail the package build on every system that builds it.
- [A fatal Rosetta failure blocks an offline first activation] → That is the intended signal; Rosetta installs once and the probe passes on every later switch.
- \[The `default-applications` JSON declaration is a second representation of the type table\] → It is rendered from the one table in the module by `pkgs.formats.json`, and the test fixtures use the same schema.

## Migration Plan

1. Add the two Python packages and the five shell programs with their tests, wire them into the overlay and check lists, and confirm that the tests build.
1. Cut each module over to `run ${lib.getExe pkgs.<name>}` and delete the inline shell and the two Python files.
1. Move the PostgreSQL data directory and delete the root activation step.
1. Activate on the Mac, move the cluster, and run the live proof.
1. Run the release gates on both systems.

Rollback is a Git revert and an activation of the previous generation. The moved cluster moves back by the reverse of the migration step if the revert lands after the move.
