## Scheduling — 2026-09-26

The owner scheduled this change after a plan review. It runs at position 4, after `separate-platform-baseline-from-roles` is implemented and passes the Mac gates. Changes 1 through 5 archive in order, each after its owner gates pass.

## 1. Python Programs

- [ ] 1.1 Create `packages/fastmail/{package.nix,pyproject.toml,src/fastmail/,tests/,tests.nix}`. Move the import-safe client from `modules/home/darwin/fastmail.py` without changing its token or JMAP behavior. Use `main(argv: Sequence[str] | None = None) -> int` for all three Python programs in this section. Each entry point owns `argparse`, parses `sys.argv[1:]` when `argv` is `None`, and its console script exits with the return value. Proof: build `.#fastmail`; run `result/bin/fastmail --help` and confirm the four subcommands.
- [ ] 1.2 Test Fastmail XML, gzip, ZIP, malformed XML, non-`feedback`, and non-XML DMARC inputs. Check the report content and the `--failures-only` result. Add a command check for a missing token. Proof: its package build runs `unittest`; its `tests.nix` check observes exit 1 and the token-file diagnostic.
- [ ] 1.3 Create `packages/apple-terminal-font/{package.nix,pyproject.toml,src/apple_terminal_font/,tests/,tests.nix}`. Move the font functions and command out of `modules/home/darwin/apple-terminal.py`; take the font name as an argument and `defaults` from `APPLE_TERMINAL_FONT_DEFAULTS`. Proof: import the module without argument or subprocess effects; build its package.
- [ ] 1.4 Test the font archive round trip, size preservation, non-`bytes` input, equal and changed Terminal domains, and missing startup profiles. Proof: `unittest` and `tests.nix` show no import in a current state and one import with unchanged size when the font differs.
- [ ] 1.5 Create `packages/symbolic-hotkeys/{package.nix,pyproject.toml,src/symbolic_hotkeys/,tests/,tests.nix}`. Use `SYMBOLIC_HOTKEYS_DEFAULTS` for command doubles. Preserve unrelated domain entries while disabling declared identifiers. Proof: `unittest` and its command check show no import for equal state, one import for changed or missing identifiers, and non-zero exit without import on export failure.

## 2. Shell Programs and Checks

- [ ] 2.1 Create `packages/neo-keyboard-layout-install/{package.nix,tests.nix}`. Compare bundle contents before replacing them and touching the layout directory. Proof: its command check covers absent, identical, and different bundles; the identical case preserves both bundle and directory mtimes.
- [ ] 2.2 Create `packages/karabiner-configuration/{package.nix,tests.nix}`. Compare before installing with file mode `0600` and directory mode `0700`. Proof: its check covers absent, identical, and changed files; the identical case preserves mtime.
- [ ] 2.3 Create `packages/default-applications/{package.nix,tests.nix}`. Accept `--declaration <json>`, compare the bundle, and check handlers before writing. Use `DEFAULT_APPLICATIONS_DUTI` and `DEFAULT_APPLICATIONS_LSREGISTER` command seams. Proof: its check observes no writes in current state, one registration for a changed bundle, one binding for a changed handler, a named `-50` skip, and fatal other `duti` or registration errors.
- [ ] 2.4 Create `packages/power-settings/{package.nix,tests.nix}`. Parse `pmset -g custom` per source and accept declared AC and battery values. Use `POWER_SETTINGS_PMSET` for a double. Proof: the check uses a Mac-captured fixture and observes no write for current state and one `-b` write when only battery differs.
- [ ] 2.5 Create `packages/rosetta/{package.nix,tests.nix}`. Probe `arch -arch x86_64 /usr/bin/true` and install only on failure. Use `ROSETTA_ARCH` and `ROSETTA_SOFTWAREUPDATE` for doubles. Proof: its check observes zero installs after a successful probe, one install after failure, and non-zero exit when installation fails.
- [ ] 2.6 Confirm each package has `meta.description`, `meta.mainProgram`, and an accurate `meta.platforms`. Use the generated `overlays.default` without a manual package list. Proof: `nix flake show` exposes Fastmail on both systems and the seven Darwin activation programs only on Darwin.
- [ ] 2.7 Register the eight `packages/<name>/tests.nix` command checks in `flake-modules/checks.nix`. Proof: build each Darwin check on the Mac; inspect the Linux check attribute set for Fastmail alone among these programs.

## 3. Module Cutover

- [ ] 3.1 Replace the Fastmail source-path wrapper in `modules/home/darwin/fastmail.nix` with `lib.getExe pkgs.fastmail` and the existing token path. Delete its old `.py` file. Proof: inspect the built Home Manager activation and run the packaged command's missing-token check.
- [ ] 3.2 Replace the Terminal source path in `modules/home/darwin/apple-terminal.nix` with `run ${lib.getExe pkgs.apple-terminal-font} <name>`. Delete its old `.py` file. Proof: rendered activation uses the package store path and has no direct Python invocation.
- [ ] 3.3 Replace `modules/home/darwin/keyboard-shortcuts.nix`'s description set with identifier strings and adjacent binding comments. Invoke `symbolic-hotkeys` entirely under `run`. Proof: rendered activation contains no `mktemp`, `defaults`, or `plutil` outside `run`.
- [ ] 3.4 Invoke the new layout and Karabiner programs from their Home Manager modules under `run`. Proof: rendered blocks contain no inline `rm`, `cp`, `touch`, or `install` commands.
- [ ] 3.5 Render the existing handler table once through `pkgs.formats.json` in `modules/home/darwin/default-apps.nix`. Invoke `default-applications` under `run`; preserve the table and its rationale. Proof: rendered JSON covers all declared types, extensions, and schemes; the activation block has no ignored binding writes.
- [ ] 3.6 Replace the power and Rosetta commands in `modules/roles/darwin/desktop/default.nix` with `lib.getExe pkgs.power-settings` and `lib.getExe pkgs.rosetta`. Preserve the declared values. Proof: rendered `extraActivation.text` contains package invocations and no bare `pmset`, `pgrep`, or `softwareupdate` calls for these concerns.
- [ ] 3.7 Leave the PostgreSQL `install -d` step and `/var/lib/postgresql/17` cluster unchanged in `modules/roles/darwin/postgresql/default.nix`. Leave the idempotent screenshot `mkdir -p` and Air role untouched. Proof: inspect the rendered PostgreSQL activation and data-directory value and the scoped diff.
- [ ] 3.8 Run the module-imports check after deleting the two Python sources. Proof: the check passes and no module interpolates a `.py` path.

## 4. Documentation and Static Verification

- [ ] 4.1 Update comments next to the changed declarations and relevant README activation guidance. Update any affected operations instructions. State compare-before-write and PostgreSQL's unchanged location. Proof: read the resulting activation and recovery instructions against the rendered declarations.
- [ ] 4.2 Build the eight command checks and the two Python packages on the Mac. Probe each check with a temporary change that removes its comparison or failure propagation, then revert the probe. Proof: each probe fails its corresponding check and the restored check passes.
- [ ] 4.3 Run `nix fmt -- --fail-on-change`, `nix flake check --print-build-logs`, `nix run .#check-darwin-build-plans`, and `nix build .#darwinConfigurations.macbook-pro.system` on the Mac in sequence. Proof: every command exits zero.
- [ ] 4.4 Run `openspec validate package-user-programs --strict` and inspect the scoped diff. Proof: validation succeeds; no replaced concern retains an inline write or ignored write error.

## 5. Owner-Only Live Gates

- [ ] 5.1 Owner: Quit Terminal.app, record mtimes for the layout directory and bundle, Karabiner file, and `FileTypes.app`, then run two `darwin-switch` activations of one revision with sudo. Proof: the second switch preserves those mtimes, reports each packaged concern as current, and has no `lsregister`, `pmset`, or `defaults import` write.
- [ ] 5.2 Owner: Run `DRY_RUN=1` against the built Home Manager activation package and compare snapshots of every path owned by the replaced Home Manager concerns. Proof: output names every program, and every content and mtime snapshot is unchanged.
- [ ] 5.3 Owner: Confirm `pmset -g custom` and `arch -arch x86_64 /usr/bin/true` before and after Mac activation. Change one declared power value, activate with sudo, and restore the declaration. Proof: activation writes only the changed power source, and restoration returns both sources to declared values.
- [ ] 5.4 Owner: Exercise safe live failure cases for `duti`, `defaults export`, and Rosetta installation when each can be induced without damaging host state. Proof: capture the failing activation status and diagnostic for each exercised case; leave any required unsafe live case open and record its deterministic command check separately.
- [ ] 5.5 Owner: Run the Darwin CI leg and the Korolev release gate after review and authorized push or host access. Proof: record CI results and Korolev command exits; do not treat a Mac evaluation of Linux outputs as a Korolev build.
