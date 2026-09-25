## Why

Word on korolev replaces nine standard `Ctrl` letter shortcuts. For example, `Ctrl+C` increases the font size and `Ctrl+V` inserts a nonbreaking hyphen. Office derives character-based shortcuts, such as `Ctrl+]`, from the first keyboard layout that Windows loads, and Windows loads the default input method first. The Windows layer makes native Neo the default, and native Neo types these characters on letter keys.

## What Changes

- Make German (Germany) QWERTZ (`0407:00000407`) the default input method.
- Keep native Neo (`0407:b0000407`) as the second German input method. The `de-DE` entry lists QWERTZ first and native Neo second.
- Enable ReNeo standalone mode. ReNeo supplies every Neo layer while QWERTZ is active and changes to extension mode while native Neo is active.
- Keep the native Neo driver script, its machine registration, and the ReNeo `RunAs` launcher.
- Update the repository check and the Windows procedure for the new default.
- **BREAKING**: After sign-in, Windows uses QWERTZ. UAC prompts, including the ReNeo `RunAs` prompt at sign-in, accept QWERTZ input unless the operator selects native Neo first.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `windows-workstation-layer`: make German QWERTZ the default input method, keep native Neo as the second German input method, enable ReNeo standalone mode, and require standard Office `Ctrl` shortcuts.

## Impact

The change affects `packages/windows-configuration/package.nix`, `packages/windows-configuration/settings.nix`, `packages/windows-configuration/files.nix`, the `packages/windows-configuration-check` checker and its tests, `docs/operations/wsl-omp-bootstrap.md`, the Windows workstation specification, and the live Windows evidence. It adds no package, privilege, Administrator operation, or startup entry. The operator applies the document and signs in again.

The `derive-windows-check-from-declaration` change made the checker read rendered policy data instead of script fragments. This change therefore exposes the German input methods as declaration data and validates that data.
