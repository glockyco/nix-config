## 1. Declare the input methods and ReNeo mode

- [ ] 1.1 Replace `native-neo-input-method` in `modules/windows/settings.nix` with `german-input-methods`. Its test requires `de-DE` tips `0407:00000407`, `0407:b0000407` first and the QWERTZ default override. Its set script orders the tips, keeps other tips, writes the list with the English placeholder, and sets the override. Render the document and inspect both scripts.
- [ ] 1.2 Set `standaloneMode = true` in the declared ReNeo settings in `modules/windows/files.nix`. Render `reneo-settings.json` and confirm the value.

## 2. Extend repository verification

- [ ] 2.1 In `packages/windows-configuration-check.py`, require the new resource, the QWERTZ default, the tip order, and ReNeo standalone mode. Reject a native Neo default. Run the focused Windows configuration check.
- [ ] 2.2 Update the Windows procedure in `docs/operations/wsl-omp-bootstrap.md` for the QWERTZ default, native Neo selection, ReNeo layout detection, and UAC input. Review the rendered procedure for account and sign-in accuracy.

## 3. Validate and review

- [ ] 3.1 Run `openspec validate default-windows-input-to-qwertz --strict`, `nix fmt -- --fail-on-change`, and `nix flake check --print-build-logs`. Resolve every failure.
- [ ] 3.2 Inspect and commit only the change-owned implementation, specification, procedure, and verification files as one atomic configuration change with a causal commit body.

## 4. Apply and prove Windows behavior

- [ ] 4.1 Test and apply the rendered document as the standard Windows user. Require drift on `german input methods` and `reneo settings` before the apply and the desired state after it.
- [ ] 4.2 Sign out, sign in, and accept the ReNeo `RunAs` prompt. Confirm that German QWERTZ is active and first in the loaded layout list, that native Neo is second, and that the managed ReNeo copy runs.
- [ ] 4.3 Start a new Word process while QWERTZ is active. Confirm with `FindKey` that `Ctrl+C`, `V`, `F`, `L`, `U`, `D`, `P`, `Q`, and `Y` invoke `EditCopy`, `EditPaste`, `SmartFind`, `LeftPara`, `Underline`, `FormatFont`, `PrintPreviewAndPrint`, `ResetPara`, and `EditRedoOrRepeat`. Copy and paste with `Ctrl+C` and `Ctrl+V` in Word and Excel.
- [ ] 4.4 Select native Neo with `Win+Space`, change the foreground window, start a new Word process, and repeat the `FindKey` check.
- [ ] 4.5 Type all Neo layers in an ordinary and an elevated application while QWERTZ is active, then while native Neo is active. Record the layout that a UAC prompt accepts in each state.
- [ ] 4.6 Record the diagnosis, commands, observed results, Office build, ReNeo version, and applied revision in `evidence.md`. Archive the change after every gate passes.
