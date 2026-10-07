## 1. Dispatch URIs through the protocol handler

- [x] 1.1 In `packages/wsl-open/package.nix`, dispatch an absolute URI with `rundll32.exe url.dll,FileProtocolHandler` and keep `explorer.exe` for translated paths. Report a missing `rundll32.exe` as an unavailable interoperation boundary and keep the 126/127 handling.
- [x] 1.2 Extend `packages/wsl-open/tests.nix` with a `rundll32.exe` double. Assert the URI argument vector for a URI with `?`, `&` and percent-escapes, that URIs do not reach `explorer.exe`, that paths do not reach `rundll32.exe`, and the missing-`rundll32.exe` error. Verify the check fails when the URI branch calls `explorer.exe` again.

## 2. Validate and activate

- [x] 2.1 Validate the change with `openspec validate fix-open-uri-query-dispatch --strict` and run the README gates `nix fmt -- --fail-on-change` and `nix flake check --print-build-logs`.
- [x] 2.2 Review, commit, merge, and activate the committed Korolev configuration under the README release procedure, keeping the previous generation.
- [x] 2.3 From a fresh Korolev login shell, run `open 'https://example.com/?x=1&y=2'` and `open` with a URI longer than 300 characters holding percent-escapes. Each opens the default browser and no Documents window, counted through the Explorer window list. `open .` still opens the directory in Explorer.
