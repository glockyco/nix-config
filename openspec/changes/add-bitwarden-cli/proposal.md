# Proposal

## Why

Both workstations need a native Bitwarden CLI so coding agents can supply approved project secrets without exposing plaintext to the model provider or committing it. The default flow should grant only the values a task needs, with vault-session access reserved for on-demand retrieval.

## What Changes

- Install `bw` through the existing platform package owners: nixpkgs on the Mac and user-scoped WinGet on Korolev.
- Keep SCCH Vaultwarden and the private Bitwarden account in separate persistent, per-user CLI data directories owned by Bitwarden.
- Make human pre-export of named task secrets, vault locking and then OMP startup the primary flow, so OMP registers the values for obfuscation without receiving a vault session.
- Document enabling OMP secret obfuscation per host as an operator-owned runtime setting. Keep the secondary on-demand flow, with its session also exported as `BW_SESSION_TOKEN` before OMP starts.
- State the limits of registration, provider-bound obfuscation and plaintext local storage. Secrets fetched after startup are not automatically registered.
- Gate each flow on human-created canary checks before using real items, including the ANITA external vLLM key, and verify native delivery, profile isolation and cleanup on both actual hosts.

## Capabilities

### New Capabilities

- `bitwarden-secrets`: Native Bitwarden CLI delivery, isolated vault profiles and human-authorized, least-privilege secret use with provider-bound obfuscation and explicit local-state limits.

### Modified Capabilities

None. The existing `user-configuration`, `windows-workstation-layer`, `darwin-dependency-builds` and `personal-omp-workstation` contracts remain in force. They define ownership, privilege, build and runtime boundaries, but none owns the cross-platform Bitwarden account and secret-use lifecycle. This capability documents OMP's existing protection without managing its runtime configuration or changing OMP itself.

## Impact

- Mac package inventory in `modules/shared/user-packages.nix`, consumed by the existing user-environment module.
- Windows application inventory in `windows/workstation.json`, its stable role ownership in `windows/Workstation.Validation.ps1`, and related validation tests.
- Operator procedures in a new `docs/operations/bitwarden.md`, linked from the README Secrets section and `docs/operations/korolev-windows.md`.
- Application-owned local state for the SCCH server at `https://password.scch.at` and a private account, assumed to use the Bitwarden US cloud until confirmed interactively.
- Operator-owned OMP obfuscation settings and host-local terminal/session state. No declarative OMP config or `secrets.yml`, plugin change, unattended login, credential migration, wrapper or background service.
- Existing age credentials and desktop/browser Bitwarden installations remain unchanged.
