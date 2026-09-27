## Scheduling — 2026-09-26

The owner scheduled this change after reviewing the plan. It runs at position 2, directly after `key-fleet-by-host`. Leave it unarchived until the owner records the Windows live result.

## 1. Record the 19-File Baseline

- [x] 1.1 After `key-fleet-by-host`, record the parent commit, `flake.lock` SHA-256, output store path, and all 19 file SHA-256 values in `baseline.md`. Build twice and prove equal store paths and hashes.
- [x] 1.2 Record parsed YAML and the exact Fork and Zen script fragments permitted to differ in design decision 11. Run the comparison against the baseline itself and prove zero differences.
- [x] 1.3 Record the current 46-resource breakdown, nine named dependencies, Ferdium package, Zed keymap and TexLab setting, PowerToys state, and stable dark-appearance behavior. Prove these facts from the built output, not from the old checker's copied constants.

## 2. Establish One Application Declaration

- [x] 2.1 Extend `packages/windows-configuration/applications.nix` with AltSnap and font release data. Derive metadata, policy selectors, URLs, and review files from entries. Prove that all 19 output hashes still match the baseline.
- [x] 2.2 Add one `byRole` selector. Remove unused `provides`, `auditDate`, empty font `files`, and repeated ReNeo path values. Prove that the role set still has ten members and the output remains byte-identical.
- [x] 2.3 Expose `passthru.declaration` with roles, applications and policies, managed identifiers, and sixteen review file names. Migrate callers and remove `passthru.document` and `passthru.renderedFiles`. Prove that declaration JSON contains no derivation output.
- [x] 2.4 Temporarily change one exact version pin. Prove that every rendered copy updates and the check needs no edit. Temporarily give one accepted self-updating role an exact policy and prove the check rejects it by role. Revert both probes and confirm baseline hashes.

## 3. Remove Evaluation-Time Reads

- [x] 3.1 Keep fetched themes as store-path members of `renderedFiles` and copy them in the build. Prove `nix eval --option allow-import-from-derivation false .#windows-configuration.drvPath` succeeds without network access.
- [x] 3.2 Keep one hexadecimal SHA-256 value for each fetched asset and derive SRI with `builtins.convertHash`. Prove that only `zen-catppuccin.json` and its two document scripts lose the three SRI members in design decision 11.

## 4. Centralize PowerShell Rendering

- [x] 4.1 Add `packages/windows-configuration/powershell.nix` with `psJson`, `psHereString`, SHA-256, subset, merge, archive, and Administrator fragments. Prove that an unsafe here-string terminator is rejected during evaluation.
- [x] 4.2 Replace single-quoted JSON interpolation and both multiline literals with the helpers. Prove that an apostrophe probe renders valid PowerShell and that all other scripts remain byte-identical. Revert the probe.
- [x] 4.3 Share the repeated subset, merge, archive, hash, and Administrator fragments. Prove that each fragment has one Nix definition and all baseline scripts remain unchanged except listed differences.
- [x] 4.4 Replace the Fork-specific merge branch with `Merge-Object`. Prove that its set script differs only in the two fragments in design decision 11.

## 5. Package the Declaration-Driven Check

- [x] 5.1 Add `packages/windows-configuration-check/{package.nix,pyproject.toml,src/,tests/}` using `buildPythonApplication`, `pyproject = true`, and `unittestCheckHook`. Prove that importing its module has no side effects and package build runs the tests.
- [x] 5.2 Add the repository-owned WinGet v3 schema, pinned DSC definitions, and `parse.ps1`. Validate shipped `configuration.winget` without `dependsOn` rewriting. Prove that the unchanged document passes and a `resourceId()` dependency or revision schema URL fails.
- [x] 5.3 Parse every document script, both Administrator scripts, and the ReNeo launcher in one `pwsh` invocation. Prove that a syntax error reports the script name and parser message.
- [x] 5.4 Check Administrator and excluded-path boundaries from parsed variable and string AST values. Remove all script-source substring assertions. Prove that a forbidden reference fails while an equivalent script refactor passes without checker changes.
- [x] 5.5 Derive expected resources, selectors, scope, and sixteen review-file names from `passthru.declaration`. Include the three primary artifacts from the fixed Windows interface. Keep schema, uniqueness, dependency, elevation, Administrator, and accepted fixed-role ownership invariants as literals. Prove a declaration-only pin update passes without a checker edit while a replaced Zen, Zed, Brave, or Ferdium role fails.
- [x] 5.6 Move `run_rejection_tests` out of the CLI path into stdlib `unittest` under `tests/`. Prove a normal command never runs self-tests and a package build does.
- [x] 5.7 Implement `main(argv: Sequence[str] | None = None) -> int` with `argparse`. Parse `sys.argv[1:]` when `argv` is `None`. Make the console script exit with the returned status. Prove malformed arguments, a missing output file, and a missing document resource each print one finding to stderr and exit 1 without a traceback or `StopIteration`. Prove unexpected programming failures still retain a traceback.
- [x] 5.8 Remove the four renderer policy assertions. Replace `checks/windows-configuration.nix` with a call to the packaged CLI; delete `checks/windows-configuration-check.py`, the temporary plain driver. Prove violating output still renders and the flake check fails with the resource name on both systems.

## 6. Prove Check Reach with Build-Time Fixtures

- [x] 6.1 Add accepted exact and self-updating fixtures. Add one-fact rejection cases for absent or invalid policies, a forbidden self-updating role, missing or conflicting selectors, managed identifiers, absent or duplicate roles, wrong scope, elevation, and Windows features. Prove each failure names its application or resource.
- [x] 6.2 Reject duplicate names, missing or `resourceId()` dependencies, a revision schema URL, absent declared applications, replaced Zen, Zed, Brave, or Ferdium identities, Brave or Ferdium startup and profile ownership, and changed review files. Prove each failure names the offending value.
- [x] 6.3 Add script syntax and forbidden Administrator path or variable cases. Prove each failure names the script and offending value.
- [x] 6.4 Temporarily disable each distinct fixture-enforced validation, observe the relevant test fail, and restore the rule. Prove the package tests pass after restoration.

## 7. Verify Rendered Output and Repository Gates

- [x] 7.1 Run the `baseline.md` comparison. Prove byte identity for 17 files and only the specified Zen SRI and Fork script differences in the other two. Prove no new or missing files and no other YAML semantic changes.
- [x] 7.2 Build `packages/windows-configuration-check` and run the packaged CLI on the built Windows output. Prove exit 0 and no self-test output during a normal invocation.
- [x] 7.3 Run `nix fmt -- --fail-on-change`, `nix flake check --print-build-logs`, `nix run .#check-darwin-build-plans`, and `nix build .#darwinConfigurations.macbook-pro.system` on the Mac. Record command results.
- [x] 7.4 Run `openspec validate derive-windows-check-from-declaration --strict`. Record the successful result.
- [x] 7.5 Review declaration, renderer, helper, checker, fixtures, and documentation. Prove no copied mutable pin or policy, duplicate source assertion, unsafe JSON interpolation, import-from-derivation, source grep, obsolete theme-path expectation, dead field, or old driver remains.
- [x] 7.6 Owner: On Korolev, run `nix flake check --all-systems --print-build-logs`. Record both systems' results; the Mac has no Linux builder. Waived by the owner on 2026-09-27; not performed.
- [x] 7.7 Owner: Review the CI result after the reviewed change reaches CI. Record the result without requesting an unapproved push.

## 8. Documentation and Windows Live Gate

- [x] 8.1 Update the Windows apply runbook. Distinguish repository schema and PowerShell syntax checks from Windows PowerShell 5.1 behavior. Document exact and self-updating policies, stable `Custom.theme` acceptance, and PowerToys module review on pin changes. Prove that its commands and paths match the implementation.
- [x] 8.2 Update README links and release guidance for `packages/windows-configuration/` and the packaged check. Prove no obsolete `modules/windows/` link remains.
- [x] 8.3 Owner: On the Windows work machine, run the runbook's `winget configure test`. Record resource states, installed exact and self-updating versions, `Custom.theme` result, and exit status in `baseline.md`. Waived by the owner on 2026-09-27; not performed.
- [x] 8.4 Owner: From the required Administrator PowerShell contexts, run both `apply-kbdneo.ps1 -Test` and `apply-zen-policies.ps1 -Test`. Record `kbdneo: desired` and `Zen policies: desired`, or exact drift and recovery, in `baseline.md`. Waived by the owner on 2026-09-27; not performed.
- [x] 8.5 Owner: Remove `GitInstancePath` from Fork settings, apply the reviewed document, open a WSL worktree in Fork, then repeat `winget configure test`. Record the observed state and desired-state result in `baseline.md`. Waived by the owner on 2026-09-27; not performed.
- [x] 8.6 Owner: Review the live evidence and archive only after tasks 8.3-8.5 pass. Record the archive decision. Waived by the owner on 2026-09-27; not performed.
