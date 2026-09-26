## Context

The owner scheduled this change at position 2 after `key-fleet-by-host`. That change relocates the renderer to `packages/windows-configuration/package.nix`, exposes it through the generated overlay, and moves the temporary assertion check to `checks/`. This change does not repeat that relocation. At HEAD, the renderer is `modules/windows/default.nix:1-7,219-257`; the direct flake call and check are `flake.nix:227-230,708`. Source references below describe HEAD; implementation paths describe the state after position 1.

- Current evaluation renders 19 files: `configuration.winget`, `apply-kbdneo.ps1`, `apply-zen-policies.ps1`, and sixteen review files. The list comes from `modules/windows/default.nix:219-257` and `modules/windows/files.nix:240-256`. The checker lists sixteen review files and two scripts separately from its document input (`packages/windows-configuration-check.py:102-121,586-593`). A direct evaluation of `windows-configuration.document` reports 46 resources: eight `Microsoft.WinGet/Package`, 22 `Microsoft.Windows/Registry`, and sixteen `Microsoft.DSC.Transitional/WindowsPowerShellScript`. Nine resources have `dependsOn`. The schema URL is the DSC `main` document URL (`modules/windows/default.nix:80-86`).
- Current roles include `browser-relay` and `communication-client` (`modules/windows/default.nix:22-33`); Brave and Ferdium are self-updating (`modules/windows/applications.nix:20-34`). Ferdium has no managed startup or profile (`modules/windows/applications.nix:27-34`). The checker still copies both identities and policy (`packages/windows-configuration-check.py:19-35,260-310`). Keep the accepted Ferdium ownership boundary and Brave's relay boundary.
- Zed's Windows-first full-editor keymap is an enforced file (`modules/windows/files.nix:83-131,337-355`). The TexLab build-on-save setting lives in Zed user settings (`modules/windows/files.nix:64-81`), not in a project build command. Dark appearance deliberately does not compare the generated active theme path (`modules/windows/settings.nix`); the checker currently searches script text for related fragments (`packages/windows-configuration-check.py:609-650`). Preserve these behaviors without another literal copy in the checker.
- PowerToys lists its enabled module keys in the renderer (`modules/windows/files.nix:133-174`). The checker copies the whole set (`packages/windows-configuration-check.py:59-95,914-930`). The list has no offline source of completeness for a later PowerToys release. The runbook must require a manual review on every PowerToys pin change.
- `packages/windows-configuration-check.py:151-172,595-598` rewrites bare `dependsOn` names into `resourceId()` expressions for validation. The pinned DSC schema's dependency form differs from WinGet's bare-name contract. The renderer normalizes names and dependencies together (`modules/windows/default.nix:67-86`). Validate the actual document with a repository-owned WinGet v3 schema.
- The current check executes fixture rejections on every invocation (`packages/windows-configuration-check.py:363-571,1053`). It unpacks raw `sys.argv` (`:586-589`) and searches for resources with unguarded `next(...)` (`:609-613,795-799,937-941`). Move self-tests to package `tests/`; expected bad arguments or missing resources need one finding and exit 1.
- `builtins.readFile` forces fetched theme paths during evaluation (`modules/windows/files.nix:244,252-254`). The renderer still has four import-time policy assertions (`modules/windows/default.nix:230-239`). The shared Zen policy still includes `EnterprisePoliciesEnabled` (`modules/shared/zen-policies.nix:11-14`); Windows excludes it with `removeAttrs` (`modules/windows/files.nix:234-236`).

The WinGet parser requires the current `main` schema URL and resolves bare-name dependencies. The pinned DSC checkout (`packages/windows-configuration-check.nix:7-12`) instead constrains `dependsOn` to `resourceId()` expressions. Keep the WinGet contract, reuse the pinned definitions for resource type and name, and state the difference in a local v3 document schema.

The `powershell` package from pinned Nixpkgs provides a prebuilt executable for `x86_64-linux` and `aarch64-darwin`. Parse all scripts with its PowerShell 7 parser. PowerShell 7 syntax acceptance alone does not prove Windows PowerShell 5.1 execution; the Windows live gate remains necessary.

## Goals / Non-Goals

**Goals:**

- One declaration per application, read by every resource that installs or configures it.
- A check that reads the declaration from the output, validates the shipped document as shipped, parses every script, and holds no copy of a pin.
- One policy owner. A policy violation is a failed check with a message, and the output still renders.
- Evaluation of the output with `allow-import-from-derivation = false`.
- The package where its kind belongs: `packages/windows-configuration/`.
- All 19 rendered files byte-identical to the baseline except the two documented file differences.

**Non-Goals:**

- Any change to what the document declares: no new resource, setting, application, or pin. The two listed differences change script text and review data without a change in behavior.
- Fetching the AltSnap, wslgit, kbdneo, or font archives with Nix. Those archives do not ship in the output, and their pins are data that the scripts verify on Windows.
- Proving on Linux that a script behaves as intended on Windows. The check proves syntax and boundary. The live test in the Windows apply section of the provisioning runbook proves behavior.
- A check that proves the PowerToys module list complete against the installed version. That list has no offline source. The check no longer carries a copy, and the runbook records the review at each PowerToys pin change.
- Windows documentation outside this change's runbook and README edits. This change owns both of those edits; there is no documentation handoff.
- Changes to the WSL `open` command. It dispatches one target through the Windows desktop (`packages/wsl-open.nix:6-49`), while this change only renders Windows configuration and checks it. Keep that separate activation boundary.

## Decisions

### 1. Consume the package and check layout from `key-fleet-by-host`

Position 1 relocates `modules/windows/default.nix` to `packages/windows-configuration/package.nix`, moves its sibling renderer files with it, and exposes `pkgs.windows-configuration`. Its overlay uses `lib.packagesFromDirectoryRecursive { inherit (final) callPackage; directory = ../packages; }` in `flake-modules/packages.nix`. This change starts from that package and adds `packages/windows-configuration-check/package.nix`; the overlay discovers the checker by directory name. The flake-level assertion remains in `checks/windows-configuration.nix`, wired by `flake-modules/checks.nix`.

Both package functions accept package-set arguments only. The check expression passes the rendered Windows package and its declaration file to the checker CLI. A package relocation is not part of this change's byte comparison: record the baseline after position 1, then compare every subsequent rendered output to it.

Alternative rejected: keep a second move task. Position 1 already makes the package layout mandatory, so a second move would target paths that no longer exist.

### 2. `applications.nix` is the single application declaration

Each entry keeps `name`, `role`, `id`, `versionPolicy`, `source`, and `scope`; an `exact` entry also keeps `version`, while a `self-updating` entry omits it. An entry whose source is not `winget` gains a `release` attribute with the data its script needs. AltSnap carries `url`, `archiveSha256`, `executableSha256`, and `hooksSha256`. The font carries `archiveSha256`, `legacyRegistryNames`, and `fonts`, and `font.nix` builds the URL from the version. `provides` leaves, because no entry uses it and `roles = [ role ]` renders the same bytes.

`files.nix` and `font.nix` receive `applications` and select entries by role through one `byRole` function in `package.nix`. Each resource derives `metadata.application` from that entry with `id`, `roles`, `source`, `versionPolicy`, and `scope`, plus `version` only for `exact`. `altsnap-package.json` becomes `builtins.toJSON ({ inherit (entry) version; } // entry.release)`, whose sorted attributes equal the current literal.

The ReNeo package directory `Microsoft\WinGet\Packages\<id>_Microsoft.Winget.Source_8wekyb3d8bbwe\ReNeo` is built once from the `keyboard-layout` entry. The launcher appends `reneo.exe` and the settings resource appends `config.json`.

Alternative rejected: keep `files.nix` data and delete the entries from `applications.nix`. The role count and the elevation policy read `applications.nix`, so that file must list every application.

### 3. The output exposes `passthru.declaration`

```text
declaration = {
  roles               = [ "browser" "browser-relay" "communication-client" ... ]; # ten names
  applications        = [ { name; role; id; versionPolicy; version ?; source; scope; } ... ];
  managedApplications = [ "7zip.7zip" ... ];
  reviewFiles         = [ "altsnap-package.json" ... ]; # sixteen names
};
```

The list includes the current Ferdium and Brave roles (`modules/windows/default.nix:22-33`, `modules/windows/applications.nix:20-34`). Release data stays in each application entry but out of the exposed declaration because the checker does not fetch those archives. `passthru.document` and `passthru.renderedFiles` leave after all callers migrate; HEAD exposes both (`modules/windows/default.nix:242-249`).

`checks/windows-configuration.nix` serializes `pkgs.windows-configuration.declaration` to a store file. The checker derives expected resources, version policies and selectors, scopes, roles, elevation, and sixteen review-file names from that file. The three required artifact names remain part of the fixed Windows CLI contract (`modules/windows/default.nix:253-255`). A package version or policy change does not require a checker edit. The renderer still owns the Zed keymap and TexLab setting (`modules/windows/files.nix:64-131`), Ferdium's package-only boundary (`modules/windows/applications.nix:27-34`), and PowerToys values (`modules/windows/files.nix:133-174`). Do not replace those values with new check literals.

### 4. The check is the single policy owner

The four policy `assert` expressions leave. Each rule moves to the check with the same meaning: every application has one valid version policy, no application is in the managed set, every declared role has exactly one application, no application is outside the role set, and no elevated resource exists except the machine-scope package resource of the `browser` role. The check accepts `exact` only with `version` and `useLatest: false`; it accepts `self-updating` only without `version` and with `useLatest: true`.

An import-time `assert` fails every evaluation that reaches the output. After `key-fleet-by-host` the output is in the overlay, so `nix flake show` and `nix build .#windows-configuration` fail with the assertion text instead of a check report. A policy violation is a review finding. The operator needs the rendered output to inspect it, and `nix flake check` is the gate that names the resource.

The `browser` role and the machine scope stay literal in the check. The specification names Zen as the only elevated resource, and that is a rule about the declaration rather than a value in it.

Keep immutable identity, version-policy scope, and ownership rules from the accepted `windows-workstation-layer` capability. The machine-scoped `browser` role remains Zen (`modules/windows/applications.nix:11-18`). The `editor`, `browser-relay`, and `communication-client` roles remain Zed, Brave, and Ferdium with self-updating policies (`modules/windows/applications.nix:2-34`). Every other application role remains exact-pinned (`modules/windows/applications.nix:35-89`). Brave and Ferdium must have no repository-owned startup or writable profile resource. The current check enforces Brave and Ferdium identities and forbids their startup resources (`packages/windows-configuration-check.py:260-310,442-517`); preserve that reach without copying version pins or application data. The document remains the declaration's projection, not a second source of mutable values. A role reassignment or conflicting profile owner fails by role name.

Alternative rejected: derive every accepted identity solely from the declaration. That would let a declaration change replace `Ferdium.Ferdium` or `Brave.Brave` and pass validation, despite the accepted fixed-role requirements.

Alternative rejected: keep the Nix asserts and reduce the check to schema validation. The audit accepted that option too. It keeps evaluation failures for review findings, and it leaves the Administrator-script boundary, which Nix cannot evaluate, in the check anyway. One owner is simpler.

### 5. The document keeps its WinGet contract; the check owns a WinGet v3 schema

The document keeps `$schema` at the `main` URL and keeps bare names in `dependsOn`. Both are the WinGet contract: the parser recognizes only that URL, and WinGet resolves dependencies by `name`. A `resourceId()` form or a revision-pinned URL would fail `winget configure` on the work machine.

The check ships `winget-configuration.schema.json` under `packages/windows-configuration-check/src/windows_configuration_check/`. It states the WinGet v3 document contract:

```text
$schema      const  "https://raw.githubusercontent.com/PowerShell/DSC/main/schemas/2023/08/config/document.json"
metadata     object, winget.processor.identifier const "dscv3"
resources    array, minItems 1, items:
  type       $ref pinned DSC definitions/resourceType.json
  name       $ref pinned DSC definitions/instanceName.json
  properties object, required
  dependsOn  array of $ref instanceName.json, uniqueItems
  metadata   object
  no additional properties
```

The `$ref` values name the `main` URLs. The checker registers every JSON file of the pinned DSC checkout under its `$id`, so the pinned revision supplies definitions. The pin moves from the temporary `checks/windows-configuration.nix` expression to `packages/windows-configuration-check/package.nix`. The document carries no revision. The check validates the shipped YAML as loaded, without a rewrite. It also requires unique resource names and existing bare-name dependencies, two rules that JSON Schema cannot express.

The `instanceName` pattern rejects a `resourceId()` entry, so the schema also rejects the form that WinGet cannot resolve.

Alternative rejected: emit `[resourceId('type', 'name')]` and pin `$schema` to the revision. Three sources refute it: the parser's `SchemaVersionAndUriMap`, the WinGet v3 reference table for `dependsOn`, and issue 5906. The pinned DSC schema itself allows only the `main` URL in `$schema`.

Alternative rejected: patch the pinned `document.resource.json` in the check. A patched upstream file hides the contract in a diff. A repository-owned schema that reuses the upstream definitions states it.

### 6. `pwsh` parses every script, and the boundary reads the syntax tree

`packages/windows-configuration-check/src/windows_configuration_check/parse.ps1` reads a JSON object of named scripts on standard input, calls `Parser::ParseInput` for each, and writes one JSON record per script: parse error messages, the `UserPath` of every `VariableExpressionAst`, the value of every `StringConstantExpressionAst` and `ExpandableStringExpressionAst`, and the value of every `keyPath` is not needed there because registry resources are data. The Python program runs one `pwsh -NoProfile -NonInteractive -File parse.ps1` for all scripts together.

The check fails when any script reports a parse error, and names the script and the message. The Administrator-script boundary reads the parsed data: `apply-kbdneo.ps1` and `apply-zen-policies.ps1` reference no variable in `env:APPDATA`, `env:LOCALAPPDATA`, `env:USERPROFILE`, and no string value that starts with `HKCU:`. The excluded-surface rule reads the same data: no registry `keyPath` and no script string contains `CloudStore`. Every substring assertion on script source leaves, including the stable dark-mode, animation, font, JSON-writer, Fork, and AltSnap checks. The declaration records no active theme-file path because Windows owns its generated `Custom.theme`.

`pwsh` parses with the PowerShell 7 grammar, and the scripts run under Windows PowerShell 5.1. The 7 grammar is a superset, so a 7-only construct passes the check and fails on Windows. The live test in the Windows apply section of the provisioning runbook runs every test script under 5.1 and is the proof for that gap.

The check depends on `powershell` on both systems. The package is a prebuilt release archive on each, so it is cached and `check-darwin-build-plans` reaches no source-built .NET package.

Alternative rejected: a Python tokenizer for PowerShell. There is none that follows the grammar, and the real parser is one prebuilt package away.

### 7. The checker is a packaged program with build-time self-tests

`packages/windows-configuration-check/` follows the Python program convention from `key-fleet-by-host`: `package.nix`, `pyproject.toml`, import-safe `src/windows_configuration_check/`, and stdlib `unittest` under `tests/`. The entry point is `main(argv: Sequence[str] | None = None) -> int`. It owns `argparse` and uses `sys.argv[1:]` only when `argv` is `None`. The console script exits with its return value. Normal imports run no check and normal invocations run no self-tests. `buildPythonApplication` uses `pyproject = true` and `unittestCheckHook`. Dependencies include `jsonschema`, `pyyaml`, and `referencing`. The command and its package tests can run `pwsh`. Package resources include `parse.ps1` and `winget-configuration.schema.json`. The DSC checkout stays pinned once in `package.nix` and is available through `passthru.dscSchemas`.

The command line is:

```sh
windows-configuration-check --schemas <dsc-checkout> --declaration <declaration.json> <output-directory>
```

Valid output returns 0. An expected failure prints one finding with a resource, script, application, or file name to stderr and returns 1. Customize `argparse`'s error path so missing arguments and bad options also return 1 through the top-level boundary. Missing resources, JSON/YAML errors, schema errors, and predictable file I/O failures use the same boundary. Avoid unguarded `next(...)` and tuple-unpacking failures. Unexpected programming errors keep a traceback.

Tests create small output directories and declarations. Accepted cases cover `exact`, `self-updating`, Brave's relay and Ferdium's package-only ownership. Rejected cases cover missing or invalid policies, selectors, roles, scopes, managed identifiers, extra elevation, Windows features, duplicate names, unknown or `resourceId()` dependencies, a revision schema URL, missing application resources, changed review files, parser errors, and Administrator-script boundary violations. Confirm each expected CLI failure is one line with exit 1. Run a mutation probe for each distinct rule, then restore the rule. `unittestCheckHook` executes these tests during the package build, not in `main()`.

`checks/windows-configuration.nix` is one flake-level `runCommand`. It runs the packaged CLI against `pkgs.windows-configuration` and its declaration with `passthru.dscSchemas`, then creates `$out`. Replace the temporary `checks/windows-configuration-check.py` driver that position 1 moved into `checks/`. Do not leave two check implementations.

### 8. `powershell.nix` renders every repeated fragment

The file exports:

```text
psJson value               '<json with each apostrophe doubled>'
psHereString text          @'\n<text>\n'@, and rejects a text with a line equal to '@
sha256Of path              (Get-FileHash -LiteralPath <path> -Algorithm SHA256).Hash.ToLowerInvariant()
testSubsetFunction         the Test-Subset definition
mergeObjectFunction        the Merge-Object definition
expandArchive { variable; label; }
                           Invoke-WebRequest, checksum test with '<label> archive checksum mismatch', Remove-Item, Add-Type, ExtractToDirectory
requireAdministrator operation
                           the principal test with 'The <operation> apply requires an Administrator PowerShell session'
```

Every `'${builtins.toJSON x}'` site uses `psJson`. The two here-string sites use `psHereString`. Each fragment renders its lines joined with the nesting of its call site, so the rendered text is unchanged. The `psHereString` rejection is a rendering precondition rather than policy, and it stays a Nix `assert`.

The Fork set script uses `mergeObjectFunction` and one `Merge-Object` call in place of its own branch. That is listed difference 1.

Alternative rejected: ship a `.psm1` module in the output. A script resource runs inside DSC with no script root, so a module would need its own install resource and an order dependency for every resource. The Nix fragments reach every site without a runtime dependency.

### 9. Evaluation reads no derivation output

`renderedFiles` maps each review file name to a store path: `pkgs.writeText` for generated content and the `fetchurl` derivation itself for a fetched file. The build copies each path. `builtins.readFile` of a derivation output leaves, and `nix eval --option allow-import-from-derivation false .#windows-configuration.drvPath` succeeds.

Each fetched file keeps its hexadecimal `sha256` in the data, because the scripts compare that form on Windows. `fetchurl` receives `hash = builtins.convertHash { hash = sha256; hashAlgo = "sha256"; toHashFormat = "sri"; }`. The `sri` attributes at `files.nix:41,46,51` and the SRI literal at `files.nix:26` leave. The `zen-catppuccin.json` review file and the `zen catppuccin theme` scripts embed that data, so they lose the three `sri` members. That is listed difference 2.

### 10. Dead data leaves

`managed-applications.nix` keeps its identifiers and states the audit date in a comment. `font.nix` drops `files = { }`, and `package.nix` composes `renderedFiles` from `files.nix` and the kbdneo JSON alone. `provides` leaves with decision 2.

### 11. Acceptance gate: 19-file baseline with two listed differences

After `key-fleet-by-host` lands, record the parent commit, `flake.lock` SHA-256, output store path, and SHA-256 of all 19 files in `baseline.md`. The files are:

```text
configuration.winget          apply-kbdneo.ps1             apply-zen-policies.ps1
altsnap-package.json         altsnap-settings.json        fork-wslgit.json
kbdneo.json                  power-toys-settings.json     reneo-settings.json
start-reneo-elevated.ps1     terminal-settings.json       zed-catppuccin-theme.json
zed-keymap.json              zed-settings.json           zen-catppuccin-logo.svg
zen-catppuccin-userChrome.css zen-catppuccin-userContent.css
zen-catppuccin.json          zen-policies.json
```

The three primary files come from `modules/windows/default.nix:253-255` at HEAD. Fourteen JSON or asset names and the ReNeo launcher come from `modules/windows/files.nix:240-256`; `kbdneo.json` is added in `modules/windows/default.nix:221-223`. The resulting set has sixteen review files and three primary files. Confirm a second build has the same store path and file hashes. Store the exact baseline comparison command and output in `baseline.md` when implementing this change.

The final gate requires:

1. Every file except `configuration.winget` and `zen-catppuccin.json` has the baseline SHA-256.
1. `zen-catppuccin.json` loses only three redundant SRI members: `userChrome.css` `sha256-mLqXUQvy7NhjZoYjgkLLDy5DVS4ruTxSCBjtidqSGJs=`, `userContent.css` `sha256-KXo8ReYkeSiSSCq0VVJiWydl5tRJR+h4/lxXMet81Eo=`, and `zen-logo.svg` `sha256-tBvov2yGWcUyoLG5hEiGlgc62zGux6CJIR1PSn7NmoM=` (`modules/windows/files.nix:37-53`).
1. Both YAML documents have equal parsed data after removing `properties.setScript` from `fork wslgit` and `properties.testScript` and `properties.setScript` from `zen catppuccin theme`.
1. The Zen theme scripts change only the embedded `$specification` JSON literal by the same three SRI removals. No other script text changes.
1. The Fork set script adds the shared `Merge-Object` definition, equal to the definition for `zed settings`, and replaces only its separate `GitInstancePath` branch with `Merge-Object $settings ([PSCustomObject]@{ GitInstancePath = (Join-Path $root 'bin\git.exe') })` (`modules/windows/files.nix:492-507`).
1. On the Windows work machine, the owner runs `winget configure test` and both Administrator scripts with `-Test`. The owner records the resulting state in `baseline.md`; the check remains unarchived until that record exists. For the Fork change, remove `GitInstancePath` from `%LOCALAPPDATA%\Fork\settings.json`, apply the new document, and confirm that Fork opens the WSL worktree. The next test must report desired state.

The repository-level comparison runs on an available supported build host. The owner-only Windows gate is not replaceable with a PowerShell 7 syntax parse. A later `separate-platform-baseline-from-roles` change moves `EnterprisePoliciesEnabled` out of `modules/shared/zen-policies.nix` and removes the Windows renderer's `removeAttrs` (`modules/shared/zen-policies.nix:11-14`, `modules/windows/files.nix:234-236`). That later change must compare against this baseline and preserve the entire Windows output byte for byte. Do not preempt that move here.

`flake.lock` stays fixed during this change's baseline comparison.

## Risks / Trade-offs

- [PowerShell 7 parses a construct that Windows PowerShell 5.1 rejects] → The owner runs the real Windows test scripts on the work machine. The repository check proves syntax and boundary only.
- [The PowerToys list changes with an upstream release] → The runbook requires review of the module set at each pin update. `modules/windows/files.nix:133-174` remains the source, not a copied checker list.
- [The check no longer pins dark-mode, animation, Zed keymap, or TexLab script text] → The renderer owns the values (`modules/windows/settings.nix`, `modules/windows/files.nix:64-131`). The byte baseline protects their present output. The live test covers Windows behavior, including `Custom.theme`.
- [A PowerShell fragment changes script folding or indentation] → The byte comparison rejects changes except the listed script fragments.
- [The schema and parser disagree on dependencies] → The local WinGet v3 schema uses pinned DSC definitions but permits bare names. The real Windows test is still required.
- [A policy violation reaches a rendered output] → That is intentional. The flake check reports the named finding and remains a release gate.
- [An expected CLI error escapes as a traceback] → A top-level error boundary covers malformed arguments and missing files or resources. Build-time fixtures exercise exit status and stderr.

## Migration Plan

1. Start after `key-fleet-by-host` and record the 19-file baseline.
1. Change the declaration, PowerShell helpers, and fetched asset handling. Compare the output after each group.
1. Package the checker and move its self-tests out of the runtime path. Replace the temporary assertion check and remove the renderer policy assertions.
1. Compare all files and allowed differences with the baseline. Run scoped package tests and repository gates.
1. Update the Windows runbook and README. Leave the change unarchived until the owner records the Windows live result.

Rollback is a Git revert. The change installs nothing on a host. Windows applies remain explicit manual operations.
