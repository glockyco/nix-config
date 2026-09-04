## 1. Python Packages

- [ ] 1.1 Create `packages/fastmail/` with `pyproject.toml` and `src/fastmail/__init__.py`, which holds the current program behind `main()`. Create `packages/fastmail.nix` with `buildPythonApplication`, `pyproject = true`, `unittestCheckHook`, and `meta` with `description`, `mainProgram = "fastmail"`, and `platforms = lib.platforms.all`. Confirm that `nix build .#fastmail` succeeds and that `result/bin/fastmail --help` lists the four subcommands.
- [ ] 1.2 Add `packages/fastmail/tests/` with fixtures for a ZIP, a gzip, and a plain XML DMARC report, a malformed XML document, and a non-`feedback` document. Assert the decoded report shape, the `--failures-only` drop of an all-pass report, the `JmapError` for each malformed input, and the empty result for a non-XML attachment. Confirm that `nix build .#fastmail` runs the tests, and that one deliberately broken assertion fails the build before the task reverts it.
- [ ] 1.3 Create `packages/apple-terminal-font/` with the font blob functions and a `main()` that takes the PostScript name as its argument and the `defaults` path from `APPLE_TERMINAL_FONT_DEFAULTS`. Create `packages/apple-terminal-font.nix` with `meta.platforms = lib.platforms.darwin`. Confirm that importing the module in a Python session performs no subprocess call and reads no argument.
- [ ] 1.4 Add unit tests for `apple-terminal-font` that round-trip `archived_font` through `font_name` and `font_size` and that reject a non-`bytes` blob. Confirm that the package build runs them.
- [ ] 1.5 Create `packages/symbolic-hotkeys/` with a `main()` that takes identifiers as arguments and the `defaults` path from `SYMBOLIC_HOTKEYS_DEFAULTS`. The program exports `com.apple.symbolichotkeys`, sets `enabled` to false for each identifier that is enabled or absent, and imports the domain only when an entry changed. Add unit tests for an all-disabled domain, an enabled entry, an absent entry, and an unchanged unrelated entry. Confirm that the package build runs them.

## 2. Activation Programs

- [ ] 2.1 Create `packages/neo-keyboard-layout-install.nix` as a `writeShellApplication` that takes the store bundle and the layout directory as arguments. The program compares with `diff -rq`, replaces the bundle and touches the directory only on difference, and reports `current` or `installed` on standard error. Confirm with `nix build` on the Mac or through the remote builder.
- [ ] 2.2 Create `packages/karabiner-configuration.nix`, which takes the generated file and the target path, creates the directory with mode `0700` only when absent, and installs the file with mode `0600` only when `cmp -s` reports a difference. Confirm with `nix build`.
- [ ] 2.3 Create `packages/default-applications.nix`, which takes `--declaration <json>` and reads it with `jq`. The program compares the bundle with `diff -rq`, replaces and registers it only on difference, and binds each type, extension, and scheme only when the read handler differs. It fails on any `duti -s` or `lsregister` error except a `duti` message that contains `(error -50)`, and takes `duti` and `lsregister` from `DEFAULT_APPLICATIONS_DUTI` and `DEFAULT_APPLICATIONS_LSREGISTER`. Confirm with `nix build`.
- [ ] 2.4 Create `packages/power-settings.nix`, which takes `--ac` and `--battery` value lists, parses `pmset -g custom` per power source, writes only a differing source, and takes `pmset` from `POWER_SETTINGS_PMSET`. Confirm with `nix build`.
- [ ] 2.5 Create `packages/rosetta.nix`, which probes with `arch -arch x86_64 /usr/bin/true`, installs with `softwareupdate --install-rosetta --agree-to-license` only when the probe fails, and exits non-zero when the installation fails. It takes both executables from `ROSETTA_ARCH` and `ROSETTA_SOFTWAREUPDATE`. Confirm with `nix build`.
- [ ] 2.6 Add every new package to the overlay list in `flake-modules/packages.nix` and to `perSystem.packages`. Confirm that `nix flake show` lists `fastmail` on both systems and the seven Darwin programs on `aarch64-darwin` alone.

## 3. Program Tests

- [ ] 3.1 Add `packages/neo-keyboard-layout-install-tests.nix` with an absent, an identical, and a differing bundle. Assert that the identical case leaves the directory and bundle mtimes unchanged, and that the other two replace the bundle and bump the directory mtime. Confirm that the check builds.
- [ ] 3.2 Add `packages/karabiner-configuration-tests.nix` with an absent, an identical, and a differing file. Assert modes `0700` and `0600`, an unchanged mtime for the identical case, and the replaced content for the differing case. Confirm that the check builds.
- [ ] 3.3 Add `packages/default-applications-tests.nix` with `duti` and `lsregister` doubles that answer from a fixture handler table and record writes. Assert that a current state records no write, that a changed bundle records one `lsregister -f`, that a differing handler records one `duti -s`, that a `(error -50)` reply continues and names the type, and that another error exits non-zero and names the application, the type, and the result. Confirm that the check builds.
- [ ] 3.4 Add `packages/symbolic-hotkeys-tests.nix` with a `defaults` double that serves a fixture domain and records `import` with its standard input. Assert no import for an all-disabled domain, one import with only the declared entry changed for an enabled entry, and a non-zero exit with no import when `export` fails. Confirm that the check builds.
- [ ] 3.5 Add `packages/apple-terminal-font-tests.nix` with a `defaults` double that serves a fixture domain with two profiles. Assert no import when the font is current, one import that preserves the size when the font differs, and no import when neither startup profile exists. Confirm that the check builds.
- [ ] 3.6 Capture `pmset -g custom` on the Mac as the fixture. Add `packages/power-settings-tests.nix` with a `pmset` double that prints it and records writes. Assert no write for a current state and a `-b` write alone when only the battery values differ. Confirm that the check builds.
- [ ] 3.7 Add `packages/rosetta-tests.nix` with `arch` and `softwareupdate` doubles. Assert no `softwareupdate` call when the probe succeeds, one call when it fails, and a non-zero exit when the installation fails. Confirm that the check builds.
- [ ] 3.8 Add `packages/fastmail-tests.nix`, which runs the built program with no token file and asserts exit `1` and the message that names `--token-file`. Confirm that the check builds on both systems.
- [ ] 3.9 Register each test in `flake-modules/checks.nix` as `<name>Command`. Confirm that `nix flake check` on `aarch64-darwin` lists every new check and that the Linux leg lists `fastmailCommand` alone.
- [ ] 3.10 Confirm that each test rejects, with one temporary probe per program that removes its comparison and writes unconditionally, and revert each probe.

## 4. Module Cutover

- [ ] 4.1 Rewrite `modules/home/darwin/fastmail.nix` to wrap `lib.getExe pkgs.fastmail` with `--token-file`, and delete `modules/home/darwin/fastmail.py`. Confirm on the Mac that `fastmail mailboxes` returns the mailbox list.
- [ ] 4.2 Rewrite `modules/home/darwin/apple-terminal.nix` to `run ${lib.getExe pkgs.apple-terminal-font} <name>`, and delete `modules/home/darwin/apple-terminal.py`. Confirm by evaluation that the activation block contains the store path of the package and no `python3` call.
- [ ] 4.3 Rewrite `modules/home/darwin/keyboard-shortcuts.nix` as a list of identifiers with the binding of each as a comment, invoked through `run ${lib.getExe pkgs.symbolic-hotkeys}`. Confirm by evaluation that the block contains no `mktemp`, `defaults`, or `plutil` call outside `run`.
- [ ] 4.4 Rewrite `modules/home/darwin/neo2.nix` and `modules/home/darwin/karabiner.nix` to one `run` line each. Confirm by evaluation that neither block contains `rm`, `cp`, `touch`, or `install`.
- [ ] 4.5 Rewrite `modules/home/darwin/default-apps.nix` to render the declaration with `pkgs.formats.json` and to invoke `run ${lib.getExe pkgs.default-applications} --declaration <file>`. Keep the type table and its rationale. Confirm by evaluation that the rendered JSON names every type, extension, and scheme the current module binds, and that the block contains no `|| true`.
- [ ] 4.6 Rewrite `modules/roles/darwin/power/default.nix` and `modules/roles/darwin/rosetta/default.nix` to call `lib.getExe pkgs.power-settings` with the declared values and `lib.getExe pkgs.rosetta`. Confirm by evaluation that `system.activationScripts.extraActivation.text` contains no bare `pmset`, `pgrep`, or `softwareupdate` call.
- [ ] 4.7 Confirm that the `moduleImports` check still passes after the two Python files are deleted, and that no file under `modules/` interpolates a `.py` path.

## 5. PostgreSQL Data Directory

- [ ] 5.1 Set `services.postgresql.dataDir` in `modules/roles/darwin/postgresql/default.nix` to `${config.system.primaryUserHome}/.local/share/postgresql/${config.services.postgresql.package.psqlSchema}`, and delete the `extraActivation` block. Confirm by evaluation that the rendered agent script names the new path and that `extraActivation.text` contains no `install -d`.
- [ ] 5.2 Update the module comment to state why the cluster lives under the user's home and why the path contains no space. Confirm by reading the file.

## 6. Live Proof on the Mac

- [ ] 6.1 Quit Terminal.app. Record `stat -f '%N %m'` for the layout directory, its bundle, `karabiner.json`, and `FileTypes.app`. Run `darwin-switch` twice on the same revision. Confirm that the second run changes no recorded mtime, reports every concern as current, and prints no `lsregister`, `pmset`, or `defaults import` line.
- [ ] 6.2 Run `initdb` from the pinned package against a temporary path whose final directory is missing. Confirm that it creates the directory, then delete it.
- [ ] 6.3 Stop the PostgreSQL agent. Run `pg_dumpall` to a file outside the cluster. Move `/var/lib/postgresql/17` to the new path with ownership preserved, and activate. Confirm that `psql -c 'select version()'` succeeds against the moved cluster before the old directory is deleted.
- [ ] 6.4 Build `home.activationPackage` for the user and snapshot every path the five Home Manager programs own. Run `DRY_RUN=1 result/activate`, confirm that the output names each program, and confirm that every snapshot is unchanged.
- [ ] 6.5 Confirm that `pmset -g custom` and `arch -arch x86_64 /usr/bin/true` report the declared state before and after the switch.
- [ ] 6.6 Change one power value in the declaration and switch. Confirm that the output reports one `pmset` write for that source alone, then revert the value.

## 7. Documentation

- [ ] 7.1 Add a decision-log entry to `docs/architecture/personal-omp-environment.md` for the packaged activation programs, the compare-before-write rule, and the user-owned PostgreSQL cluster.
- [ ] 7.2 Update the `packages/` row of the README layout table to name the user programs and the activation programs. Confirm that `nix fmt -- --fail-on-change` accepts the table.

## 8. Verify the Complete Change

- [ ] 8.1 Run `nix fmt -- --fail-on-change`.
- [ ] 8.2 Run `nix flake check --print-build-logs` on `x86_64-linux` with the Nix the host declares.
- [ ] 8.3 Run `nix flake check --print-build-logs`, `nix run .#check-darwin-build-plans`, and `nix build .#darwinConfigurations.macbook-pro.system` on the Mac.
- [ ] 8.4 Run `openspec validate package-user-programs --strict`.
- [ ] 8.5 Review the final diff by package, test, module, and documentation. Confirm that no module keeps an inline write, that no program keeps a `|| true` on a write, and that the two Python files are gone.
