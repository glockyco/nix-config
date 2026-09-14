## Why

Zed's Vim mode replaces familiar Windows `Ctrl` shortcuts with Vim commands in normal, visual, and insert modes. The editor should keep Vim's modal language without making standard Windows and VS Code shortcuts depend on the active Vim mode.

## What Changes

- Add a declared Windows Zed `keymap.json` beside the existing declared `settings.json`.
- Make standard Windows and VS Code `Ctrl` shortcuts take precedence over Vim bindings in full editors.
- Restore direct copy, cut, paste, select-all, undo, redo, save, find, replace, quick-open, command-palette, tab, and editor-close shortcuts.
- Remove Vim's `Ctrl+W` prefix delay by restoring direct editor close on `Ctrl+W`.
- Keep Vim's unmodified modal keys, motions, operators, text objects, registers, and command palette.
- Keep terminal input and non-editor surfaces outside this override so they retain their own context-specific shortcuts.
- Preserve macOS behavior. The macOS Zed configuration continues to use `Command` for application shortcuts and keeps Vim's `Control` bindings.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `windows-workstation-layer`: declare and converge Zed's user keymap, and require Windows-first `Ctrl` behavior in full editors while Vim mode remains enabled.

## Impact

The change affects `modules/windows/files.nix`, the rendered Windows review files, the Windows configuration check, the Windows workstation specification, and the live Windows apply evidence. It adds no package, service, privilege, startup entry, or Nix activation behavior.
