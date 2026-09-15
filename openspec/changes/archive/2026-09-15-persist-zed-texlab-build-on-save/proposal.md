## Why

Zed does not pass repository-local TexLab workspace settings through its WSL remote extension, so saving a LaTeX file does not start the configured build. The Windows settings convergence would also remove the manually repaired user setting on its next apply.

## What Changes

- Declare TexLab build-on-save in the Windows-owned Zed user settings.
- Verify the rendered Windows settings and a real Zed-to-WSL save-triggered build.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `windows-workstation-layer`: Preserve TexLab build-on-save behavior for LaTeX projects opened through Zed's WSL workspace support.

## Impact

The change affects `modules/windows/files.nix`, the rendered Windows configuration check, and the live `%APPDATA%\Zed\settings.json` produced by the standard Windows apply workflow. Project-specific LaTeX commands remain in each repository.
