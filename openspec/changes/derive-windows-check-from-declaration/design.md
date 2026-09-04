## Context

See `proposal.md` for the motivation. The facts that shape the approach:

- This change starts after `declare-typed-host-options`, `connect-fleet-over-tailnet`, `key-fleet-by-host`, `separate-platform-baseline-from-roles`, and `package-user-programs` are archived. `flake-modules/packages.nix` owns `overlays.default` and `perSystem.packages`, and `flake-modules/checks.nix` owns every repository check. The overlay builds `windows-configuration` with `final.callPackage ../modules/windows { }`, and `checks.windowsConfiguration` calls `packages/windows-configuration-check.nix` with the overlay attribute as its argument. `separate-platform-baseline-from-roles` moved `EnterprisePoliciesEnabled` out of `modules/shared/zen-policies.nix` and deleted the `removeAttrs` compensation in `files.nix`. `package-user-programs` set the Python convention: `packages/<name>/` with `pyproject.toml`, `src/<module>/` with an `argparse` `main()`, `tests/` with fixtures run by `pytestCheckHook`, and `packages/<name>.nix` with `buildPythonApplication` and `meta`.
- `modules/windows/default.nix` is a function `{ lib, pkgs }` that returns a `runCommand`. Nothing under `modules/windows/` is a module. The `moduleImports` check reads `./modules` (`flake.nix:246-249`) and accepts the directory because its `default.nix` names every sibling with `import ./<file>`.
- The rendered output has eighteen files: `configuration.winget`, `apply-kbdneo.ps1`, `apply-zen-policies.ps1`, and fifteen review files (`default.nix:204-206,222-231`). The document has 43 resources: 8 of type `Microsoft.WinGet/Package` and `Microsoft.DSC.Transitional/WindowsPowerShellScript` with an application, 19 of type `Microsoft.Windows/Registry`, and 16 further script resources. Eight resources carry `dependsOn`, and every entry is a bare resource name. The `$schema` value is `https://raw.githubusercontent.com/PowerShell/DSC/main/schemas/2023/08/config/document.json` (`default.nix:75-76`).
- The WinGet parser maps that exact URL to its 0.3 document parser and reports `WINGET_CONFIG_ERROR_UNKNOWN_CONFIGURATION_FILE_VERSION` for any other `$schema` value (`src/Microsoft.Management.Configuration/ConfigurationSetParser.cpp`, `SchemaVersionAndUriMap` and `ConfigurationSetParser::Create` in `microsoft/winget-cli` at `master`). The WinGet v3 reference defines `dependsOn` as "an array of resource `name` values" and its example uses a bare name. `microsoft/winget-cli` issue 5906 records that `winget dsc validate` accepts only bare names and rejects the `resourceId()` form.
- The pinned DSC schema at `45b10078ba49d9f9ec13b72c1040368eac9838e9` constrains `$schema` to the `main` URL with an `enum` (`schemas/2023/08/config/document.json`), constrains `dependsOn` items to `^\[resourceId\(...\)\]$` (`schemas/2023/08/config/document.resource.json`), and constrains `name` to `^[a-zA-Z0-9 ]+$` (`schemas/2023/08/definitions/instanceName.json`). Every `$id` and every `$ref` in that checkout names the `main` URL. The DSC schema and the WinGet parser therefore disagree on `dependsOn`, and the document must follow the parser.
- `powershell` in the pinned Nixpkgs is version 7.6.2. Its source is the official release archive for each of `x86_64-linux` and `aarch64-darwin`, its `meta.platforms` lists both systems, and it is a `stdenv.mkDerivation` over prebuilt files with `autoPatchelfHook` on Linux. A probe on `x86_64-linux` ran `pwsh -NoProfile -NonInteractive -File` with `HOME=/nonexistent`, parsed 33 scripts from the current output through `[System.Management.Automation.Language.Parser]::ParseInput`, reported no parse error, reported two errors for a script with a missing parenthesis, and listed `env:APPDATA` among the variable references of a script that reads `$env:APPDATA`. The run took 1.4 seconds.
- `builtins.toJSON` emits attribute names in sorted order, so a JSON literal is unchanged when the same attributes come from another expression. No JSON literal that the current output embeds in a single-quoted PowerShell string contains an apostrophe, so the quoting helper renders the same bytes today.
- The download, verify, and extract sequence appears four times with the same five lines. Each copy sits inside a `try` block at the same nesting depth relative to its `''` string. The Fork resource reads and merges its settings with its own branch instead of `Merge-Object` (`files.nix:411-429`).
- `pkgs.formats.yaml` renders each script as one double-quoted, line-folded scalar. A change to one script therefore changes the folding of that scalar and no other line.
- `allow-import-from-derivation = false` makes Nix reject a `builtins.readFile` of a derivation output during evaluation. The current output reads three `fetchurl` outputs at `files.nix:191,198-200`.

## Goals / Non-Goals

**Goals:**

- One declaration per application, read by every resource that installs or configures it.
- A check that reads the declaration from the output, validates the shipped document as shipped, parses every script, and holds no copy of a pin.
- One policy owner. A policy violation is a failed check with a message, and the output still renders.
- Evaluation of the output with `allow-import-from-derivation = false`.
- The package where its kind belongs: `packages/windows-configuration/`.
- Every rendered file byte-identical to the baseline except the two listed differences.

**Non-Goals:**

- Any change to what the document declares: no new resource, setting, application, or pin. The two listed differences change script text and review data without a change in behavior.
- Fetching the AltSnap, wslgit, kbdneo, or font archives with Nix. Those archives do not ship in the output, and their pins are data that the scripts verify on Windows.
- Proving on Linux that a script behaves as intended on Windows. The check proves syntax and boundary. The live test in runbook section 12 proves behavior.
- A check that proves the PowerToys module list complete against the installed version. That list has no offline source. The check no longer carries a copy, and the runbook records the review at each PowerToys pin change.
- Documentation outside runbook section 12, the README layout row, and the decision-log entry. `align-documentation-with-fleet` owns the rest.

## Decisions

### 1. Move the package to `packages/windows-configuration/`

`git mv modules/windows packages/windows-configuration`. The overlay line in `flake-modules/packages.nix` becomes `windows-configuration = final.callPackage ../packages/windows-configuration { }`. `modules/` then holds module lists and shared data alone, and the `moduleImports` scope is unchanged.

The output derivation names no source path, so the store path of `nix build .#windows-configuration` is identical before and after the move. That equality is the proof for this step.

Alternative rejected: leave the directory and document the exception. The audit named the mismatch, and the fix is one rename.

### 2. `applications.nix` is the single application declaration

Each entry keeps `name`, `role`, `id`, `version`, `source`, and `scope`. An entry whose source is not `winget` gains a `release` attribute with the data its script needs. AltSnap carries `url`, `archiveSha256`, `executableSha256`, and `hooksSha256`. The font carries `archiveSha256`, `legacyRegistryNames`, and `fonts`, and `font.nix` builds the URL from the version. `provides` leaves, because no entry uses it and `roles = [ role ]` renders the same bytes.

`files.nix` and `font.nix` receive `applications` and select their entry by role with one `byRole` function in `default.nix`. Each resource builds `metadata.application` as `{ id; roles = [ role ]; source; version; scope; }` from that entry, which is the attribute set the output already renders. `altsnap-package.json` becomes `builtins.toJSON ({ inherit (entry) version; } // entry.release)`, whose sorted attributes equal the current literal.

The ReNeo package directory `Microsoft\WinGet\Packages\<id>_Microsoft.Winget.Source_8wekyb3d8bbwe\ReNeo` is built once from the `keyboard-layout` entry. The launcher appends `reneo.exe` and the settings resource appends `config.json`.

Alternative rejected: keep `files.nix` data and delete the entries from `applications.nix`. The role count and the elevation policy read `applications.nix`, so that file must list every application.

### 3. The output exposes `passthru.declaration`

```text
declaration = {
  roles               = [ "browser" "editor" ... ];          # eight names
  applications        = [ { name; role; id; version; source; scope; } ... ];
  managedApplications = [ "7zip.7zip" ... ];
  reviewFiles         = [ "altsnap-package.json" ... ];      # fifteen names
};
```

`release` data stays out of the declaration, because the check does not verify archive checksums that Nix does not fetch. `passthru.document` and `passthru.renderedFiles` leave, because nothing reads them.

`checks.nix` writes `builtins.toJSON pkgs.windows-configuration.declaration` to a store file and passes it to the check. The check derives from it: the expected set of application resources, each pin, each scope, each role, the elevation set, and the file set.

### 4. The check is the single policy owner

The four `assert` expressions at `default.nix:212-221` leave. Each rule moves to the check with the same meaning: no application without a version, no application in the managed set, exactly one application per declared role and no application outside the role set, and no elevated resource except the machine-scope package resource of the `browser` role.

An import-time `assert` fails every evaluation that reaches the output. After `key-fleet-by-host` the output is in the overlay, so `nix flake show` and `nix build .#windows-configuration` fail with the assertion text instead of a check report. A policy violation is a review finding. The operator needs the rendered output to inspect it, and `nix flake check` is the gate that names the resource.

The `browser` role and the machine scope stay literal in the check. The specification names Zen as the only elevated resource, and that is a rule about the declaration rather than a value in it.

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

The `$ref` values name the `main` URLs, and the check registers every JSON file of the pinned DSC checkout under its `$id`, so the pinned revision supplies the definitions. The pin lives in `packages/windows-configuration-check.nix` alone, and the document carries no revision. The check validates the shipped YAML as loaded, with no rewrite, and adds two rules that JSON Schema cannot express: every `dependsOn` name is the `name` of another resource in the document, and no `name` repeats.

The `instanceName` pattern rejects a `resourceId()` entry, so the schema also rejects the form that WinGet cannot resolve.

Alternative rejected: emit `[resourceId('type', 'name')]` and pin `$schema` to the revision. Three sources refute it: the parser's `SchemaVersionAndUriMap`, the WinGet v3 reference table for `dependsOn`, and issue 5906. The pinned DSC schema itself allows only the `main` URL in `$schema`.

Alternative rejected: patch the pinned `document.resource.json` in the check. A patched upstream file hides the contract in a diff. A repository-owned schema that reuses the upstream definitions states it.

### 6. `pwsh` parses every script, and the boundary reads the syntax tree

`packages/windows-configuration-check/src/windows_configuration_check/parse.ps1` reads a JSON object of named scripts on standard input, calls `Parser::ParseInput` for each, and writes one JSON record per script: parse error messages, the `UserPath` of every `VariableExpressionAst`, the value of every `StringConstantExpressionAst` and `ExpandableStringExpressionAst`, and the value of every `keyPath` is not needed there because registry resources are data. The Python program runs one `pwsh -NoProfile -NonInteractive -File parse.ps1` for all scripts together.

The check fails when any script reports a parse error, and names the script and the message. The Administrator-script boundary reads the parsed data: `apply-kbdneo.ps1` and `apply-zen-policies.ps1` reference no variable in `env:APPDATA`, `env:LOCALAPPDATA`, `env:USERPROFILE`, and no string value that starts with `HKCU:`. The excluded-surface rule reads the same data: no registry `keyPath` and no script string contains `CloudStore`. Every substring assertion on script source leaves, including the dark-appearance, animation, font, JSON-writer, Fork, and AltSnap checks.

`pwsh` parses with the PowerShell 7 grammar, and the scripts run under Windows PowerShell 5.1. The 7 grammar is a superset, so a 7-only construct passes the check and fails on Windows. The live test in runbook section 12 runs every test script under 5.1 and is the proof for that gap.

The check depends on `powershell` on both systems. The package is a prebuilt release archive on each, so it is cached and `check-darwin-build-plans` reaches no source-built .NET package.

Alternative rejected: a Python tokenizer for PowerShell. There is none that follows the grammar, and the real parser is one prebuilt package away.

### 7. The check is a packaged program with fixtures

`packages/windows-configuration-check/` follows the `package-user-programs` convention: `pyproject.toml`, `src/windows_configuration_check/` with `__main__`, `schema.py`, `policy.py`, `scripts.py`, `parse.ps1`, and `winget-configuration.schema.json`, and `tests/` with fixtures. `packages/windows-configuration-check.nix` builds it with `buildPythonApplication`, depends on `jsonschema`, `pyyaml`, and `referencing`, wraps `pwsh` into `PATH`, holds the DSC checkout as `passthru.dscSchemas`, and sets `meta` with `description`, `mainProgram`, and `platforms`. `pytestCheckHook` runs the fixtures with `pwsh` in `nativeCheckInputs` and the checkout in `DSC_SCHEMAS`.

The command line is:

```sh
windows-configuration-check --schemas <dsc-checkout> --declaration <declaration.json> <output-directory>
```

The program exits 0 on success. It exits 1 with one line per finding that names the resource, script, application, or file.

Each fixture is a small output directory and declaration that a test writes. One fixture is accepted. Each rejection fixture changes one fact: a missing version, a rendered version that differs from the declared one, `useLatest` true, a managed identifier, a role with two applications, a declared role with none, a `HKLM\` key path, an elevated user-scope package, an elevated registry resource, a Windows feature type, a machine-scope package without `securityContext`, a duplicate name, a `dependsOn` name that no resource declares, a `dependsOn` entry in `resourceId()` form, a `$schema` that names a revision, a declared application that the document omits, a review file that the declaration does not name, a script with a syntax error, an Administrator script that reads `$env:APPDATA`, and an Administrator script that names an `HKCU:` path. Each rejection test asserts the exit status and the named subject.

`checks.windowsConfiguration` in `flake-modules/checks.nix` is one `runCommand` that runs the program against `pkgs.windows-configuration` with the declaration file from decision 3 and `passthru.dscSchemas`, then touches `$out`. `packages/windows-configuration-check.py` is deleted.

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

`managed-applications.nix` keeps its identifiers and states the audit date in a comment. `font.nix` drops `files = { }`, and `default.nix` composes `renderedFiles` from `files.nix` and the kbdneo JSON alone. `provides` leaves with decision 2.

### 11. Acceptance gate: byte identity with two listed differences

`baseline.md` records the parent commit, the SHA-256 of `flake.lock`, the store path of `nix build .#windows-configuration`, and the SHA-256 of each of the eighteen files at the parent commit.

The gate at the final revision:

1. Every file except `configuration.winget` and `zen-catppuccin.json` has the SHA-256 recorded in `baseline.md`.

1. `zen-catppuccin.json` differs from the baseline only by the removal of these three members: `"sri":"sha256-mLqXUQvy7NhjZoYjgkLLDy5DVS4ruTxSCBjtidqSGJs="` under `userChrome.css`, `"sri":"sha256-KXo8ReYkeSiSSCq0VVJiWydl5tRJR+h4/lxXMet81Eo="` under `userContent.css`, and `"sri":"sha256-tBvov2yGWcUyoLG5hEiGlgc62zGux6CJIR1PSn7NmoM="` under `zen-logo.svg`.

1. `configuration.winget` loaded as YAML equals the baseline document loaded as YAML, after both sides drop `properties.setScript` of the resource named `fork wslgit` and `properties.testScript` and `properties.setScript` of the resource named `zen catppuccin theme`.

1. The two `zen catppuccin theme` scripts differ from the baseline only in their `$specification = '...'` literal, by the same three removed members.

1. The `fork wslgit` set script differs from the baseline in two places and nowhere else. First, the script starts with the `Merge-Object` definition and one blank line, identical to the first eleven lines of the `zed settings` set script. Second, the lines

   ```text
   $gitPath = Join-Path $root 'bin\git.exe'
   if ($null -eq $settings.PSObject.Properties['GitInstancePath']) {
     $settings | Add-Member -NotePropertyName GitInstancePath -NotePropertyValue $gitPath
   } else {
     $settings.GitInstancePath = $gitPath
   }
   ```

   become

   ```text
   Merge-Object $settings ([PSCustomObject]@{ GitInstancePath = (Join-Path $root 'bin\git.exe') })
   ```

1. On the work machine, `winget configure test` per runbook section 12 reports the same state as before the change, and the two Administrator scripts report `kbdneo: desired` and `Zen policies: desired` with `-Test`.

1. For listed difference 1: the operator removes `GitInstancePath` from `%LOCALAPPDATA%\Fork\settings.json`, runs `winget configure` with the new document, and confirms that the `fork wslgit` test then reports the desired state and that Fork still opens the WSL worktree.

Steps 1 to 5 run on `korolev` with a short Python script that the change keeps under `baseline.md` as the gate command. Steps 6 and 7 are the live proof.

`flake.lock` does not change while the change is open.

## Risks / Trade-offs

- [The 7 grammar accepts a construct that 5.1 rejects] → The live test runs every test script under 5.1. Decision 6 records the gap.
- [The check no longer proves the PowerToys module list complete] → The literal list was a copy tied to one version. Runbook section 12 records the review at each PowerToys pin change, and the declaration is the single source.
- [The check no longer asserts the dark-appearance and animation values] → Those were substring matches on source. The declared settings are data in `settings.nix`, and the live test and the post-apply confirmation in the runbook prove them.
- [A fragment renders at a different nesting than its call site] → The gate compares every script byte for byte. A whitespace difference fails step 1 or step 3.
- \[`pwsh` cannot start in the build sandbox\] → The probe ran with an unwritable `HOME` and `-NoProfile`, and the program sets `-NonInteractive`. The check phase of the package proves it on each system.
- \[`winget configure` rejects the unchanged document because of a WinGet update\] → The document does not change its contract, so the risk is the same as before the change. The live test is step 6.
- [A policy violation now reaches a rendered output] → That is the intent of decision 4. `nix flake check` remains a release gate.

## Migration Plan

1. Record the baseline as decision 11 states.
1. Move the package and confirm the store path is unchanged.
1. Land the declaration, helper, and evaluation changes in the order of `tasks.md`. After each group, confirm that every file is unchanged except the listed differences.
1. Land the check and remove the asserts and the old script.
1. Run the repository gates on both systems.
1. Run the live proof on the work machine and record the result in `baseline.md`.

Rollback is a Git revert. The change installs nothing on any host, and the document keeps its contract with WinGet.
