## Context

The generated package overlay lives in `flake-modules/packages.nix`, with `packages/<name>/package.nix` and optional sibling `tests.nix`. Checks live in `flake-modules/checks.nix`. The desktop role imports the power and Rosetta declarations from `modules/roles/darwin/desktop/{power,rosetta}.nix`. PostgreSQL remains in `modules/roles/darwin/postgresql/postgresql.nix`. Use these paths rather than introducing a second convention.

Home Manager invokes `run` in `modules/home/darwin/neo2.nix:19-26`, `modules/home/darwin/karabiner.nix:55-58`, and `modules/home/darwin/apple-terminal.nix:16-18`. The hotkey block invokes `mktemp`, `defaults export`, and `plutil` outside it (`modules/home/darwin/keyboard-shortcuts.nix:68-77`). The remaining write defects and their current locations appear in `proposal.md`. Fastmail has an import-safe `main()` (`modules/home/darwin/fastmail.py:444-503`); the Terminal font client does not (`modules/home/darwin/apple-terminal.py:9,56-94`).

## Goals / Non-Goals

**Goals:**

- Package and test eight repository-owned user or activation programs.
- Make repeated activation a no-op for the seven activation concerns replaced here.
- Stop activation on an unexpected platform-command failure.
- Make the Home Manager concerns write nothing under `DRY_RUN`.

**Non-Goals:**

- Change the declared layouts, Karabiner rules, handlers, shortcuts, font, power values, or PostgreSQL settings.
- Rework OMP activation or the Air's mount agent. `modules/roles/darwin/air-client/network-shares.nix` belongs to the removable Air role.
- Package the screenshot directory creation. Its `run mkdir -p` is already dry-run-safe and idempotent (`modules/home/darwin/screenshots.nix:15-17`).
- Remove `|| true` from a `duti -d` or `duti -x` read with no handler. These reads represent an absent binding (`modules/home/darwin/default-apps.nix:303-345`).

## Decisions

### 1. Use the Python convention defined by `key-fleet-by-host`

Use its `packages/<name>/package.nix`, `pyproject.toml`, `src/<module>/`, stdlib `unittest`, `buildPythonApplication`, and expected-error contract. Each Python program defines `main(argv: Sequence[str] | None = None) -> int`. It owns `argparse`, parses `sys.argv[1:]` when `argv` is `None`, and its console script exits with the returned status. This change applies that convention to `fastmail`, `apple-terminal-font`, and `symbolic-hotkeys`. The Fastmail parser and `JmapError` handler already live in `main()` (`modules/home/darwin/fastmail.py:444-499`). Move them without a second CLI convention. Move Terminal's module-level argument read and subprocess work into the new entry point (`modules/home/darwin/apple-terminal.py:9,56-94`). Keep its `archived_font`, `font_name`, and `font_size` as importable pure functions (`modules/home/darwin/apple-terminal.py:12-50`). Implement symbolic-hotkey domain parsing with `plistlib` and report expected command errors in one line; do not mask unexpected Python exceptions.

### 2. Package five shell activation concerns

Each of `neo-keyboard-layout-install`, `karabiner-configuration`, `default-applications`, `power-settings`, and `rosetta` has a `packages/<name>/package.nix` that builds a `writeShellApplication`. Each takes declared values as arguments, uses a seam for a macOS executable that command tests replace with a double, and declares `meta.description`, `meta.mainProgram`, and `meta.platforms = lib.platforms.darwin`. Fastmail declares `lib.platforms.all`. The other two Python programs are Darwin-only. `packages/<name>/tests.nix` runs each built command against fixed state and checks outputs, mutations, and failures. Python unit tests also run during package builds.

**Alternative:** declare Darwin programs available on Linux to run their tests there. Reject this because `/usr/bin/defaults`, `pmset`, `softwareupdate`, and `duti` have Darwin behavior. The Darwin check leg owns these command tests.

### 3. Invoke packages from modules, not source files

Home Manager invokes each program through `run ${lib.getExe pkgs.<name>}`. Place the entire shortcut operation behind `run`; the current `defaults export` and temporary-file creation precede the helper (`modules/home/darwin/keyboard-shortcuts.nix:69-76`). Do not add a second dry-run switch to the programs. The desktop role invokes power and Rosetta as root from `system.activationScripts.extraActivation.text`; this hook has no Home Manager helper. Delete the two `.py` source paths from `modules/home/darwin/fastmail.nix:16` and `apple-terminal.nix:17` after the modules use packages.

### 4. Compare the owned state before mutation

| Program                       | State read                                           | Mutates only when                                                  |
| ----------------------------- | ---------------------------------------------------- | ------------------------------------------------------------------ |
| `neo-keyboard-layout-install` | Store and installed bundle contents                  | The bundle is absent or differs; then touch the directory.         |
| `karabiner-configuration`     | Generated and installed JSON contents                | The target is absent or differs; create its directory if absent.   |
| `default-applications`        | Bundle contents and each `duti` handler              | The bundle or a binding differs; register the changed bundle once. |
| `symbolic-hotkeys`            | Parsed `defaults export com.apple.symbolichotkeys -` | A declared identifier is enabled or missing.                       |
| `apple-terminal-font`         | Parsed `defaults export com.apple.Terminal -`        | A startup or default profile has another font.                     |
| `power-settings`              | `pmset -g custom` per power source                   | A declared value differs for that source.                          |
| `rosetta`                     | Execution of an `x86_64` binary                      | The execution probe fails.                                         |

`diff -rq` ignores the writable copy's mode difference from the store. Touch the layout directory only after replacing its bundle: the directory mtime triggers compilation (`modules/home/darwin/neo2.nix:16-26`). Keep Karabiner's compared copy, rather than a `home.file` store symlink: the configuration is currently copied for Karabiner to edit (`modules/home/darwin/karabiner.nix:51-58`).

Use `plistlib` to preserve unrelated preference entries and Terminal profile font sizes. The font's current `archived_font` function writes an NSKeyedArchiver blob (`modules/home/darwin/apple-terminal.py:12-31`); do not replace it with a string. Both preference programs skip `defaults import` for an equal domain. Report `current` or the changed names on standard error.

### 5. Keep one file-type declaration and narrow its error exception

Keep the type table and measured rationale in `modules/home/darwin/default-apps.nix:19-67`. Render one JSON declaration with `pkgs.formats.json`, containing the bundle and `{ app, uti }`, `{ app, extension, uti }`, and `{ app, scheme }` bindings. Pass it to `default-applications --declaration <file>`. Its package performs the reads, writes, and error handling. The current code already checks a handler before binding, but ignores failed writes (`modules/home/darwin/default-apps.nix:303-345`). Fail a `duti -s` call unless its diagnostic identifies `(error -50)`; print the skipped type. Fail a `lsregister -f` error. Keep the present `duti -d`/`-x` missing-handler read behavior.

If registration fails after replacing the bundle, restore the prior copy (or remove a newly installed copy). Otherwise the next activation sees equal bundle contents and skips the registration that failed. The check must prove that the next run retries and succeeds.

**Alternative:** retain `|| true` for binding writes. Reject it because it masks a wrong app identifier or a failed handler binding.

### 6. Keep hotkey identifiers, not unused descriptions

Convert the `disabled` attribute set to a list of identifiers. Keep each binding as a comment beside its identifier. The existing activation reads only `builtins.attrNames disabled` (`modules/home/darwin/keyboard-shortcuts.nix:9-76`). `symbolic-hotkeys` disables only declared identifiers and retains all other domain entries. It imports the domain once only if the parsed result differs.

**Alternative:** keep the descriptions as attribute values. Reject it because no program consumes the values.

### 7. Probe Rosetta execution and compare power sources

Probe Rosetta with `arch -arch x86_64 /usr/bin/true`. The current daemon probe does not establish that an `x86_64` binary runs, and installation failure is swallowed (`modules/roles/darwin/desktop/rosetta.nix:4-10`). Attempt installation only after a failed execution probe; fail activation if `softwareupdate` fails. Preserve the declared `pmset -c sleep 0 displaysleep 10` and `-b sleep 1 displaysleep 15` values (`modules/roles/darwin/desktop/power.nix:9-12`). Parse `pmset -g custom` for AC and battery. Write only a differing source.

### 8. Keep PostgreSQL's directory preparation

The cluster remains at `/var/lib/postgresql/17`. Preserve the idempotent `/usr/bin/install -d -o ${config.system.primaryUser} -g staff -m 0700` step, which prepares the root-owned parent for the user agent (`modules/roles/darwin/postgresql/postgresql.nix:35-40`). Do not move data, remove the activation step, or require an `initdb` relocation proof. This step does not replace a cluster or change its contents.

**Alternative:** move the cluster under the user's home and let `initdb` make its directory. Reject it because the existing cluster contains research data and must keep its location. Do not add a redundant `test -d` guard to an already idempotent operation.

### 9. Test built commands against observable state

Each `tests.nix` uses command doubles and fixtures to exercise absent, current, changed, and failed states. Assert no write or mtime change in a current state and the specific changed result when state differs. Check `neo-keyboard-layout-install` directory touches; Karabiner's `0700` directory and `0600` file; one `lsregister -f` per changed bundle; the documented `duti -50` exception and fatal other errors; no preference import on an equal domain or failed export; per-source `pmset` writes; and Rosetta probe/install failure. Fastmail's Python tests cover XML, gzip, ZIP, malformed and non-report DMARC inputs, and `--failures-only`; its command check covers a missing token. Command checks are registered in `flake-modules/checks.nix`, not manually copied into the overlay. Check files live beside packages as `tests.nix`.

### 10. Verify built commands and rendered activation

Build the packages and checks, inspect the rendered activation commands, and verify the documentation on the Mac. Command doubles prove that an unchanged state causes no write and that safe failures propagate. The Home Manager `run` helper prevents its commands from executing under `DRY_RUN`. CI builds the checks on both platforms.

## Risks / Trade-offs

- `duti` identifies the exceptional `-50` result by diagnostic text. A future message change needs an explicit decision; tests pin the intended exception.
- Terminal.app can rewrite its preferences on exit (`modules/home/darwin/apple-terminal.py:89-94`). Quit it before applying a font change.
- Preference caches can delay an export after import. The next activation still compares parsed state rather than importing unconditionally.
- Darwin-only command checks require a Darwin builder. CI runs the Darwin and Linux check legs; Linux runs Fastmail checks, not Darwin activation programs.
- Rosetta installation can fail without a network. Fatal activation makes that missing dependency visible.

## Migration Plan

1. Add eight package directories and their `tests.nix` files. Run the scoped package checks on the Mac.
1. Cut the Home Manager modules and desktop role over to package invocations. Delete the original two Python files.
1. Update affected comments, README activation instructions, and relevant operations documentation.
1. Run repository release gates on the Mac. Review CI results for both supported platforms.

Rollback restores the preceding generation and prior module declarations. The PostgreSQL directory and cluster remain in place, so no data migration or reverse move is necessary.
