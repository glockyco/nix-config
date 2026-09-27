## Scheduling — 2026-09-26

The owner scheduled this change after reviewing the plan. It runs at position 2, directly after `key-fleet-by-host`.

## Why

The current checker repeats the renderer's data. It copies ten roles, the Catppuccin palette, the PowerToys module set, and eighteen non-document file names: sixteen review files and two Administrator scripts (`packages/windows-configuration-check.py:19-121`). It also repeats the Zen hashes, native Neo pin, wslgit pin, and AltSnap pin (`:766-794,817-884`). The renderer declares those values in `modules/windows/default.nix:8-33`, `modules/windows/files.nix:4-61,133-174,197-219`, and `modules/windows/font.nix:2-30`. The check duplicates Zed's control bindings (`packages/windows-configuration-check.py:122-148,945-983`) while the renderer owns the keymap (`modules/windows/files.nix:83-131`). A changed declaration therefore needs a checker edit.

The checker changes `dependsOn` to `resourceId()` before schema validation (`packages/windows-configuration-check.py:151-172,595-598`). It does not validate the document as shipped. It also searches script source for PowerShell fragments (`:609-750,752-815,829-846,914-930`); equivalent scripts can fail these checks. Its rejection fixtures run on every normal invocation (`:363-571,1053`), and malformed arguments fail during tuple unpacking (`:586-589`). A missing resource can fail at `next(...)` (`:609-613,795-799,937-941`) with an uncaught traceback.

The renderer reads fetched theme derivations during evaluation (`modules/windows/files.nix:244,252-254`). Its AltSnap and font release data repeat their application entries (`modules/windows/applications.nix:54-60,81-88`, `modules/windows/files.nix:4-10`, `modules/windows/font.nix:2-30`). PowerShell fragments repeat in `modules/windows/files.nix:275-332,640-690`; the Fork resource implements a separate object merge (`:492-507`). Single-quoted JSON literals lack apostrophe escaping (`:300,327,347,352,363,386,439,470,550,570`).

The current output has 19 files: three primary artifacts and sixteen review files (`modules/windows/default.nix:219-257`, `modules/windows/files.nix:240-256`). Its document has 46 resources: eight WinGet packages, 22 registry entries, and sixteen scripts. The baseline must measure this output, including Ferdium, Zed's keymap and TexLab setting, and the stable dark-appearance behavior (`modules/windows/applications.nix:27-34`, `modules/windows/files.nix:64-131`, `modules/windows/settings.nix:247-278`).

## What Changes

- Start from the `packages/windows-configuration/package.nix` package that `key-fleet-by-host` relocates and the generated overlay that exposes `pkgs.windows-configuration`. Do not move the package a second time.
- Make `applications.nix` the sole declaration of every application, including AltSnap and font release data. Derive script metadata and version selectors from it.
- Expose `passthru.declaration` with roles, application policies, managed identifiers, and review-file names. Do not expose fetched contents through this declaration.
- Package the checker as `packages/windows-configuration-check/package.nix` with `pyproject.toml`, `src/`, and `tests/`. Use `buildPythonApplication` and `unittestCheckHook`. Its import-safe `main(argv: Sequence[str] | None = None) -> int` owns `argparse`. The console script exits with its return value. Expected input errors produce one exit-1 finding. Normal invocations never run self-tests.
- Wire the flake assertion through `checks/windows-configuration.nix`. Validate the unmodified WinGet document against a repository-owned v3 schema that reuses the pinned DSC definitions. Keep the WinGet parser's current schema URL and bare-name dependencies.
- Parse document scripts, both Administrator scripts, and the ReNeo launcher with `pwsh`. Check privilege boundaries from syntax-tree values instead of searching script source.
- Remove the renderer's four policy assertions (`modules/windows/default.nix:230-239`). The check becomes the policy owner, while failed policy still leaves a rendered output for review.
- Keep fixed Zen, Zed, Brave, and Ferdium role identity and ownership invariants. Only Zed, Brave, and Ferdium may self-update. Derive mutable versions, selectors, and rendered files from the declaration without copying them into the checker.
- Centralize PowerShell quoting, subset and merge functions, archive verification, SHA-256, and Administrator guards in `powershell.nix`. Keep fetched theme assets as store paths until the build. Derive SRI hashes from hexadecimal hashes.
- Remove dead fields and repeated package paths. Preserve the current Ferdium ownership boundary, Zed shortcuts and TexLab setting, PowerToys declaration, and stable dark-appearance test.
- Record byte hashes for all 19 rendered files before editing. Require byte identity except the specified Fork script and Zen hash-data differences.
- Update the Windows apply runbook and README in this change. The runbook tells the operator to run `winget configure test` before applying the configuration and explains the Administrator `-Test` scripts.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `windows-workstation-layer`: derives checks from the declaration, validates the document as shipped, parses scripts, avoids evaluation-time fetches, owns policy in the check, and gives expected CLI failures a stable error boundary.

## Impact

Implementation changes `packages/windows-configuration/`, adds `packages/windows-configuration-check/`, and replaces the temporary `checks/windows-configuration.nix` and its plain Python driver that `key-fleet-by-host` establishes. It updates `flake-modules/checks.nix`, the Windows apply section of `docs/operations/wsl-omp-bootstrap.md`, README, and related rationale comments. The overlay discovers both packages from their `package.nix` files. The check adds prebuilt Nixpkgs `powershell` on both systems; its build runs Python self-tests without invoking the normal CLI.

Only `configuration.winget` and `zen-catppuccin.json` may change their bytes. The allowed document differences are the Fork merge implementation and removal of duplicate Zen SRI values from two scripts. Every other rendered file remains byte-identical. The later `separate-platform-baseline-from-roles` change moves `EnterprisePoliciesEnabled` out of `modules/shared/zen-policies.nix` and removes the renderer's `removeAttrs`; that change must preserve the Windows output bytes measured here (`modules/shared/zen-policies.nix:11-14`, `modules/windows/files.nix:234-236`).
