## Scheduling — 2026-09-05

This change is deferred, not canceled or completed. It is not a prerequisite for working OMP or Tailscale. [Near-term priorities](../../../docs/architecture/personal-omp-environment.md#near-term-priorities) govern scheduling.

Small acceptance-record corrections support the current OMP and Tailscale checks. They do not authorize these refactor tasks or the separate broad documentation and planning-store migration.

OpenSpec CLI counts describe artifact and task state, not scheduling authorization. All unchecked tasks remain preserved. Execution resumes only when a concrete maintenance or use requirement warrants it and the owner schedules and reviews the plan again.

## 1. Record the Rendered Baseline

- [ ] 1.1 Record the parent commit, `flake.lock` checksum, output store path, and SHA-256 of all eighteen rendered files in `baseline.md`. Confirm that a second build produces the same paths and hashes.
- [ ] 1.2 Record the parsed YAML data and the exact Fork and Zen theme script fragments that design decision 11 permits to change. Confirm that the comparison script reports no difference against the baseline itself.

## 2. Move the Windows Package

- [ ] 2.1 Move `modules/windows/` to `packages/windows-configuration/` with Git history preserved. Update the overlay call site, and confirm that the output derivation and every rendered file remain byte-identical.
- [ ] 2.2 Remove the old directory from module-import ownership. Confirm that `modules/` contains modules and shared module data only and that the module-import check still passes.

## 3. Establish One Application Declaration

- [ ] 3.1 Extend `applications.nix` with the AltSnap and font release data. Derive their resource metadata, URLs, versions, and review files from those entries.
- [ ] 3.2 Add one `byRole` selector and derive every application's rendered metadata from its entry. Delete the unused `provides`, `auditDate`, empty `files`, and repeated ReNeo package path values.
- [ ] 3.3 Add `passthru.declaration` with roles, applications, managed identifiers, and review file names. Delete `passthru.document` and `passthru.renderedFiles`, and confirm the declaration JSON contains no derivation output.
- [ ] 3.4 Change one temporary application pin in the declaration. Confirm that every applicable rendered location changes while the check needs no edit, then revert the probe.

## 4. Remove Evaluation-Time Reads

- [ ] 4.1 Make each fetched theme asset a store-path member of `renderedFiles` and copy it during the build. Confirm that `nix eval --option allow-import-from-derivation false .#windows-configuration.drvPath` succeeds without network access.
- [ ] 4.2 Keep one hexadecimal SHA-256 value per fetched asset and derive the SRI form with `builtins.convertHash`. Remove every duplicate SRI member and literal.
- [ ] 4.3 Compare the output with `baseline.md`. Confirm that only `zen-catppuccin.json` and the corresponding scripts lose the three listed SRI members.

## 5. Centralize PowerShell Rendering

- [ ] 5.1 Add `packages/windows-configuration/powershell.nix` with `psJson`, `psHereString`, SHA-256, subset, merge, archive, and Administrator fragments. Reject an unsafe here-string terminator with an evaluation assertion.
- [ ] 5.2 Replace every single-quoted JSON interpolation with `psJson` and both multiline literals with `psHereString`. Confirm that an apostrophe probe renders valid PowerShell and that all baseline scripts otherwise remain byte-identical.
- [ ] 5.3 Replace every repeated subset, merge, archive, hash, and Administrator block with the shared fragment. Confirm that each fragment has one definition in Nix.
- [ ] 5.4 Replace the Fork-specific merge branch with `Merge-Object`. Confirm that its script differs only by the two fragments listed in design decision 11.

## 6. Package a Declaration-Driven Check

- [ ] 6.1 Create `packages/windows-configuration-check/` as an import-safe Python application with the repository-owned WinGet v3 schema, `parse.ps1`, and fixture tests. Package it with the pinned DSC schemas and prebuilt `powershell` dependency.
- [ ] 6.2 Validate `configuration.winget` exactly as shipped. Register every pinned DSC schema by `$id`, preserve the WinGet `main` schema URL and bare-name dependencies, and remove the pre-validation rewrite.
- [ ] 6.3 Parse every document script, both Administrator scripts, and the ReNeo launcher in one `pwsh` invocation. Report each parser error with its script name.
- [ ] 6.4 Check Administrator and excluded-path boundaries from parsed variable and string AST values. Delete every source-substring assertion.
- [ ] 6.5 Derive expected roles, applications, pins, scope, elevation, and review files from `passthru.declaration`. Keep only schema, uniqueness, dependency, elevation, and Administrator-boundary invariants as check literals.
- [ ] 6.6 Delete the renderer's four policy assertions and make the packaged check the single policy owner. Confirm that a violating output still renders while the check fails with the resource name.
- [ ] 6.7 Replace `packages/windows-configuration-check.py` with the packaged program and wire `checks.windowsConfiguration` through `flake-modules/checks.nix`. Confirm the check runs on both supported systems.

## 7. Prove Check Reach with Fixtures

- [ ] 7.1 Add one accepted fixture and rejection fixtures for missing or mismatched pins, `useLatest`, managed applications, missing or duplicate roles, wrong scope, forbidden elevation, and Windows features. Confirm each failure names the application or resource.
- [ ] 7.2 Add rejection fixtures for duplicate names, missing dependencies, `resourceId()` dependencies, a revision schema URL, missing declared applications, and review-file drift. Confirm each failure names the differing value.
- [ ] 7.3 Add script fixtures for a syntax error and each forbidden Administrator variable or path. Confirm the parser or boundary check names the script and offending value.
- [ ] 7.4 Temporarily remove one fixture-enforced validation at a time. Confirm its fixture fails to fail, then restore the validation before continuing.
- [ ] 7.5 Confirm that an implementation-only PowerShell refactor with equal parsed values needs no check edit, then revert the probe.

## 8. Verify Rendered Identity and Live Behavior

- [ ] 8.1 Run the comparison from `baseline.md`. Require byte identity for every file except `configuration.winget` and `zen-catppuccin.json`, and require exactly the semantic and fragment differences listed in design decision 11.
- [ ] 8.2 Run `nix fmt -- --fail-on-change`.
- [ ] 8.3 Run `nix flake check --all-systems --print-build-logs` on `korolev` through the configured Darwin remote builder.
- [ ] 8.4 Run `nix flake check --print-build-logs`, `nix run .#check-darwin-build-plans`, and `nix build .#darwinConfigurations.macbook-pro.system` on the Mac.
- [ ] 8.5 Run `openspec validate derive-windows-check-from-declaration --strict`.
- [ ] 8.6 On the Windows work machine, run the runbook's `winget configure test` and both Administrator `-Test` commands. Confirm the state matches the baseline.
- [ ] 8.7 Remove `GitInstancePath` from the Fork settings, apply the new document, and confirm that Fork opens the WSL worktree and the next test reports desired state.
- [ ] 8.8 Review the final diff by declaration, renderer, helper, check, fixture, and documentation. Confirm that no duplicate pin, policy assertion, unsafe JSON interpolation, import-from-derivation, source grep, dead field, or compatibility path remains.

## 9. Documentation

- [ ] 9.1 Update runbook section 12 to distinguish repository validation from the Windows live test. Include the PowerToys review that must run when its version changes.
- [ ] 9.2 Add a dated architecture decision for declaration-derived checks, check-owned policy, parser-based PowerShell validation, and network-free evaluation.
- [ ] 9.3 Update the README layout row for `packages/windows-configuration/` and the packaged check. Confirm `nix fmt -- --fail-on-change README.md` passes.
