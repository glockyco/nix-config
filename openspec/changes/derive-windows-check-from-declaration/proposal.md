## Scheduling — 2026-09-05

This change is deferred, not canceled or completed. It is not a prerequisite for working OMP or Tailscale. [Near-term priorities](../../../docs/architecture/personal-omp-environment.md#near-term-priorities) govern scheduling.

Small acceptance-record corrections support the current OMP and Tailscale checks. They do not start this Windows renderer and check refactor or the separate broad documentation and planning-store migration.

OpenSpec CLI counts describe artifact and task state, not scheduling authorization. Requirements and unchecked tasks remain preserved. Work resumes only when a concrete maintenance or use requirement warrants it and the owner schedules and reviews the plan again.

## Why

The Windows layer has one declaration and one check, and the check carries a second copy of the declaration. `packages/windows-configuration-check.py` restates the role set (`:19-28`), the Catppuccin palette (`:29-51`), the PowerToys module set (`:52-88`), the review file set (`:95-113`), the kbdneo pins (`:554-562`), the wslgit pins (`:587-593`), the AltSnap pins (`:613-619`), and the Zen theme hashes (`:515-526`) that `modules/windows/default.nix`, `files.nix`, and `font.nix` already declare. A pin bump is two edits, and the check proves only that the two copies agree. The policy rules exist twice as well: `modules/windows/default.nix:212-221` asserts them at import time, and `windows-configuration-check.py:140-216` re-implements them and still allows a `zen policies` elevated resource (`:212-216`) that no resource declares.

The 2026-09-04 audit found three further defects in what the check proves. The schema validation runs on a rewritten document: `windows-configuration-check.py:116-137` replaces every `dependsOn` entry with a `resourceId()` expression before validation (`:334`), so the YAML that ships is never validated. Most script assertions grep PowerShell source for substrings such as `SetClientAreaAnimation(0x1043, 0, [ref]$enabled, 3)` (`:355-419`, `:467-479`, `:738-747`), so a refactor breaks the check while a wrong value passes. Evaluation of the output reads fetched files with `builtins.readFile` (`modules/windows/files.nix:191,198-200`), which forces the fixed-output fetches during evaluation and makes `nix flake show` depend on the network.

The renderer itself repeats data and code. AltSnap and the terminal font are declared in `applications.nix:32-38,58-67` and again in `files.nix:4-10,347-352` and `font.nix:2-4,103-108`, and `font.nix:62-63` hardcodes `JetBrainsMono-3.3.0.zip` next to its own `version`. `Test-Subset` and `Merge-Object` appear twice (`files.nix:222,250` and `:568,594`), and the Fork resource re-implements the merge a third time (`:425-429`). The download, verify, and extract sequence appears four times (`default.nix:175-179`, `files.nix:319-323,402-406`, `font.nix:73-77`). Fourteen sites interpolate JSON into a single-quoted PowerShell string with no escaping, so one apostrophe in a Zed setting would truncate the string. Finally, `modules/windows/` is a package: the flake calls it with `callPackage`, and nothing under it is a module.

## What Changes

- Move `modules/windows/` to `packages/windows-configuration/`. The overlay line in `flake-modules/packages.nix` points at the new directory, and `modules/` holds modules and shared data alone.
- Make `applications.nix` the single declaration for every application, including the release data of AltSnap and the font. `files.nix` and `font.nix` receive the application list and derive resource metadata and versions from it.
- Expose the declaration through `passthru.declaration`: the role set, the application list, the managed-application identifiers, and the review file names.
- Replace the Python check with a packaged program under `packages/windows-configuration-check/` that receives the declaration as JSON and asserts the shipped artifact against it. The check keeps only invariants as literals: schema, unique names, dependency existence, the elevation policy, and the Administrator-script boundary.
- Validate the shipped `configuration.winget` byte for byte against a WinGet Configuration v3 schema that the check owns. That schema reuses the pinned DSC definitions for `type` and `name` and states the WinGet `dependsOn` and `$schema` contract explicitly. The document keeps its current `$schema` URL and bare-name `dependsOn` values, because the WinGet parser recognizes only that URL and resolves dependencies by name.
- Parse every embedded script, both Administrator scripts, and the ReNeo launcher with `pwsh` through `[Management.Automation.Language.Parser]::ParseInput`. Assert the Administrator-script boundary on the parsed variable references and string constants. Drop every substring assertion.
- Remove the four policy `assert` expressions from the renderer. The check is the single policy owner, and a policy violation fails the check instead of every evaluation of the output.
- Add `powershell.nix` with one JSON quoting helper, one here-string helper, and one Nix function for each repeated PowerShell fragment: the subset test, the object merge, the archive download and verification, the SHA-256 expression, and the Administrator check.
- Keep the fetched theme files as store paths and copy them in the build. Evaluation reads no derivation output. Keep one hash form per fetched file and derive the other with `builtins.convertHash`.
- Delete dead data: `managed-applications.nix` `auditDate`, `font.nix` `files = { }`, the unused `provides` role list, and the re-literalized ReNeo package path.
- Record the acceptance gate: every rendered file is byte-identical to the baseline except two listed differences, and `winget configure test` on the work machine reports the same state as before.
- Update runbook section 12 so it names what the repository check proves and what only the live test proves.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `windows-workstation-layer`: requires the declaration to be the single source for the check, requires the check to validate the shipped document as shipped and to parse every script, requires evaluation of the output to read no network, and moves policy ownership from evaluation to the check.

## Impact

The change affects `modules/windows/` (moved to `packages/windows-configuration/`), `packages/windows-configuration-check.nix`, `packages/windows-configuration-check.py` (replaced by `packages/windows-configuration-check/`), `flake-modules/packages.nix`, `flake-modules/checks.nix`, `docs/operations/wsl-omp-bootstrap.md` section 12, `README.md`, and the architecture decision log.

It adds `powershell` from Nixpkgs as a check dependency on both systems. The package is a prebuilt release archive for `x86_64-linux` and `aarch64-darwin`, so `check-darwin-build-plans` reaches no source-built .NET package.

It changes the rendered artifact in two listed places and nowhere else. The Fork resource uses the shared merge function in its set script, and the duplicate SRI hash leaves the Zen theme data. Every other rendered file is byte-identical, and the acceptance gate in `design.md` measures that.

This change assumes that `declare-typed-host-options`, `connect-fleet-over-tailnet`, `key-fleet-by-host`, `separate-platform-baseline-from-roles`, and `package-user-programs` are archived. It follows the flake-parts layout, the overlay, and the Python packaging convention that those changes established. `align-documentation-with-fleet` owns every documentation edit outside runbook section 12, the README layout row, and the decision-log entry.
