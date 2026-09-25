## Why

Zen updates itself through its vendor channel. On 2026-09-25, korolev ran Zen `1.22.2b` against the exact pin `1.21.16b`, so the document test reported drift, and a full apply would downgrade the browser. The exact pin creates recurring drift that is not a configuration defect.

## What Changes

- Change the Zen package from the exact policy to the self-updating policy. The document omits a version and requires the latest WinGet version, as for Zed, Brave, and Ferdium.
- Keep Zen's machine scope, elevated installer, policy script, and theme resources.
- Update the repository check and the Windows procedure for the new self-updating set.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `windows-workstation-layer`: add Zen to the applications that use the self-updating version policy.

## Impact

The change affects `packages/windows-configuration/applications.nix`, the `packages/windows-configuration-check` checker and its tests, `docs/operations/wsl-omp-bootstrap.md`, and the Windows workstation specification. It adds no package, privilege, or startup entry. The Zen installer keeps the only elevated document resource.
