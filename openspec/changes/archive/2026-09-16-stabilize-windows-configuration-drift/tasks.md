## 1. Model application version policies

- [x] 1.1 Add explicit `exact` and `self-updating` version policies to the Windows application declaration; render Zed and Brave without `version` and with `useLatest: true`, then inspect the rendered package resources.
- [x] 1.2 Update the Windows configuration check and rejection fixtures for both valid policies and invalid field combinations; run the focused check and confirm that a probe with each invalid combination fails.

## 2. Stabilize dark appearance

- [x] 2.1 Remove active-theme-path ownership from the dark-appearance test and set scripts while retaining dark application mode, dark system mode, disabled transparency, and Bloom wallpaper; inspect the rendered scripts.
- [x] 2.2 Run the focused Windows configuration check and a read-only live test; require the existing `Custom.theme` state to report dark appearance as desired.

## 3. Reconcile documentation and retained plans

- [x] 3.1 Update the Windows apply procedure to describe self-updating applications, exact-pinned applications, and the prohibition on downgrading vendor-updated software; verify the procedure against the rendered document.
- [x] 3.2 Reconcile the proposal, design, delta specification, and tasks of `derive-windows-check-from-declaration` with both version policies and stable dark-appearance validation; run its strict OpenSpec validation without starting its deferred implementation.

## 4. Validate and commit

- [x] 4.1 Run `openspec validate stabilize-windows-configuration-drift --strict`, `nix fmt -- --fail-on-change`, and the platform-applicable flake check; resolve every failure.
- [x] 4.2 Inspect and commit only the drift-policy implementation, specifications, procedures, retained-plan corrections, and verification files as one atomic change with a causal commit body.

## 5. Prove Windows convergence

- [x] 5.1 Build a fresh reviewed Windows artifact and run `winget configure test` as the standard user; require Zed, Brave, and dark appearance to report desired without changing the machine.
- [x] 5.2 Apply the complete document as the standard user, then require every document resource and both Administrator-script tests to report desired.
- [x] 5.3 Record the installed and catalog versions, pre-apply results, post-apply results, WinGet version, and applied revisions in `evidence.md`; confirm that the older Zed and Brave versions were not installed.
- [x] 5.4 Unblock `prefer-standard-zed-control-shortcuts`, complete its Zed editor and terminal checks, and record its separate acceptance evidence.
