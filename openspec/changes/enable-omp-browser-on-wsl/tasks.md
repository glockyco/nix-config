## 1. NixOS Browser Runtime

- [x] 1.1 Add the tested Chromium shared-library providers to `programs.nix-ld.libraries` in `modules/nixos/programs.nix`. Confirm that `nix eval` reports every package in the `korolev` configuration and that the OMP wrapper closure still contains no Chromium package.
- [x] 1.2 Add an `ompBrowserRuntime` check that inspects the built WSL system path for each required shared-library name under `share/nix-ld/lib`. Confirm that `nix build .#checks.x86_64-linux.ompBrowserRuntime --print-build-logs` passes.
- [x] 1.3 Remove one library provider temporarily and confirm that `ompBrowserRuntime` fails for its missing shared-library name. Restore the declaration and confirm that the check passes again.

## 2. Windows Relay Browser

- [x] 2.1 Add `Brave.Brave` version `151.1.93.138` to the Windows application declaration with role `browser-relay` and user scope. Confirm that Zen remains the only application with role `browser` and that Brave is absent from the centrally managed application audit.
- [x] 2.2 Update the Windows configuration renderer and validator for exactly one pinned, user-scope `browser-relay` application. Reject a missing relay browser, `Brave.Brave` with another role or scope, an unpinned declaration, and any startup resource for Brave.
- [x] 2.3 Build `packages.windows-configuration` and `checks.x86_64-linux.windowsConfiguration`. Confirm that the rendered WinGet document contains the pinned Brave package without elevation and contains no Brave startup or default-browser resource.
- [x] 2.4 Remove the Brave declaration temporarily and confirm that the Windows validation gate fails. Restore the declaration and confirm that the gate passes again.

## 3. Operating Procedures

- [x] 3.1 Add a WSL runbook section for the managed-browser smoke. State that OMP owns its Chromium download and require the smoke after each OMP update.
- [x] 3.2 Add a WSL runbook section for the one-time relay setup. Generate the extension under the Windows user's local application data, create the dedicated `OMP Relay` Brave profile, load the unpacked extension manually, and keep relay use on demand.
- [x] 3.3 Add an architecture decision that records the `nix-ld` boundary, the dedicated Brave role, the manual extension boundary, and the rejection of wrapper library paths and employer-managed browsers.

## 4. Live Acceptance

- [x] 4.1 Build and activate `nixosConfigurations.korolev`. Confirm that activation does not change the OMP Chromium, profile, cache, or configuration paths.
- [x] 4.2 Use the actual OMP managed-browser interface to open `https://example.com` and capture a screenshot. Confirm that the page renders and that the browser daemon reports no missing shared library.
- [x] 4.3 Test and apply the rendered WinGet configuration as the interactive Windows user. Confirm that the pinned Brave version installs without elevation and that Zen remains the declared interactive browser.
- [ ] 4.4 Run the documented extension installer, create the dedicated Brave profile, and load the unpacked extension. Open one dedicated tab and confirm that an OMP relay session adopts that tab without controlling a Zen tab or another Brave profile.
- [ ] 4.5 Restart Windows and sign in. Confirm that Brave and the relay daemon remain stopped until requested, then repeat the relay connection check.

## 5. Verification

- [ ] 5.1 Run `nix fmt -- --fail-on-change`.
- [ ] 5.2 Run `nix flake check --print-build-logs` on `korolev` and confirm exit 0.
- [ ] 5.3 Run `openspec validate enable-omp-browser-on-wsl --strict`.
- [ ] 5.4 Review the final diff. Confirm that it contains no browser binary, OMP cache or profile path ownership, wrapper-level library path, extension deployment, Windows startup entry, or per-extension default-browser association.
