## Why

The Darwin host runs eight programs at activation or from the user's shell that no package builds and no check exercises. Two are Python files that a module interpolates by path: `modules/home/darwin/fastmail.nix:15` runs `python3 ${./fastmail.py}`, a 503-line JMAP client with a DMARC report decoder, and `modules/home/darwin/apple-terminal.nix:17` runs `${pkgs.python3}/bin/python3 ${./apple-terminal.py}`. `apple-terminal.py:9` reads `sys.argv[1]` at import time and `apple-terminal.py:56-94` executes at module level, so no test can import it. Every shell program under `packages/` is a `writeShellApplication` with a sibling `*-tests.nix` that runs it against doubles. The Python programs have neither.

The six remaining programs are inline shell strings in activation blocks, and most of them rewrite host state on every switch. `neo2.nix:21-26` removes and recopies the keyboard layout bundle and bumps the directory mtime, which the module's own comment at `neo2.nix:16-17` says makes macOS recompile every layout. `karabiner.nix:57` reinstalls `karabiner.json` on every switch. `default-apps.nix:376-379` deletes and recopies `FileTypes.app` and reruns `lsregister -f`, and `default-apps.nix:308-345` ends every `duti` call in `|| true`. `keyboard-shortcuts.nix:69-76` runs `mktemp`, `defaults export`, and `plutil` outside `run`, so a Home Manager dry run writes files. `power.nix:10-11` runs `pmset` unconditionally. `rosetta.nix:6-10` decides from a process name and calls `softwareupdate`, which needs the network. `postgresql.nix:38-39` runs `install -d` as root on every switch because the user agent cannot create its cluster under `/var/lib`.

The 2026-09-04 audit recorded each of these. A second activation of the same generation is therefore not a no-op, which hides real changes in the activation output, and a wrong bundle identifier or a missing binary passes silently.

## What Changes

- Package `fastmail` as a Python application under `packages/` with a `main()` entry point, `meta`, and unit tests with DMARC fixtures in ZIP, gzip, and XML form. The Home Manager module wraps the package with the token path as it does today.
- Package the Terminal.app font program as `apple-terminal-font` with a `main()` entry point, a `defaults` seam, unit tests for the font blob round trip, and a command test against a `defaults` double.
- Replace the symbolic hotkeys activation block with a packaged `symbolic-hotkeys` program that edits the exported domain with `plistlib`, imports it only when a shortcut changes, and runs under `run`. Replace the `disabled` attribute set with a list of identifiers whose bindings are comments.
- Replace each remaining inline activation block with one packaged, tested `writeShellApplication`: `neo-keyboard-layout-install`, `karabiner-configuration`, `default-applications`, `power-settings`, and `rosetta`. Each program reads the current state, compares it with the declared state, mutates only what differs, and fails on an error it does not expect. `default-applications` tolerates only the documented LaunchServices `-50` result.
- Move the PostgreSQL data directory under the primary user's home so that the launchd user agent creates its own cluster and activation creates no directory. **BREAKING**: the existing cluster moves once by hand.
- Add a `*-tests.nix` sibling for every new program and register each as a repository check.

## Capabilities

### New Capabilities

- `darwin-host-activation`: how the Darwin host applies state that Nix cannot link from the store. Activation reads before it writes, changes only what differs, fails on an unexpected error, and writes nothing in a dry run.

### Modified Capabilities

- `repository-quality-gates`: every program a host installs or runs at activation is a package with a check that exercises its behavior.

## Impact

The change affects `modules/home/darwin/{fastmail,apple-terminal,neo2,karabiner,default-apps,keyboard-shortcuts}.nix`, the two Python files beside them, `modules/roles/darwin/{power,rosetta,postgresql}/default.nix`, the overlay and check lists under `flake-modules/`, and `packages/`, which gains eight programs with their tests.

Host behavior changes in three observable ways. A second activation of the same generation changes no file under `~/Library/Keyboard Layouts`, `~/.config/karabiner`, or `~/Applications`, calls no `lsregister`, `pmset`, or `defaults import`, and the activation output states that each concern is current. A failed `duti` binding, a failed Rosetta installation, or a malformed `defaults` domain fails activation instead of printing a warning. The PostgreSQL cluster lives under the user's home.

The acceptance gate is a live proof on the Mac for each activation concern, a deterministic test for each program, and the existing release gates. Every activation program declares `meta.platforms = lib.platforms.darwin`, so its test builds on the Darwin continuous-integration leg, on the Mac, and from korolev through the remote builder that `connect-fleet-over-tailnet` introduced.

This change assumes that `declare-typed-host-options`, `connect-fleet-over-tailnet`, `key-fleet-by-host`, and `separate-platform-baseline-from-roles` are archived. Packages reach modules as `pkgs.<name>` from `overlays.default`, checks are declared in `flake-modules/checks.nix`, and platform gating derives from `meta.platforms`.
