## Windows acceptance evidence

Recorded on 2026-09-16 against Zed `1.19.2` (`df181c6f58d02677b385fa947d6bfde6d3530078`).

### Applied artifact

- Windows configuration artifact: `/nix/store/h8jbc7830b530ck8gm9hv4837l7nca1d-windows-workstation-configuration`
- Windows staging directory: `C:\Temp\windows-configuration-reviewed-3b316e1`
- Keymap revision: `488933d772893f4390e48c5cb3ae7734919cbf70`
- Drift-policy revision used for the safe apply: `3b316e1a92da4c30577d01da8ad34aa6288d297a`

The pre-apply `winget configure test` reported only `zed keymap` as drift. The complete document applied successfully. The post-apply test reported every resource in the desired state.

### Editor shortcuts

A dedicated `C:\Temp\zed-keymap-smoke.nix` buffer exercised the live Windows Zed process.

- In normal mode, `Ctrl+A` selected the complete buffer and `Ctrl+C` copied its exact text. `Ctrl+V` replaced that selection with clipboard text.
- In insert mode, `Ctrl+A` and `Ctrl+C` selected and copied the complete buffer. A typed edit followed by `Ctrl+Z` restored the original file content.
- In visual-line mode, `Ctrl+C` copied the selected first line.
- `Ctrl+F` found and selected `find target`.
- `Ctrl+K Ctrl+C` used the VS Code base-keymap chord and commented the current Nix line. `Ctrl+Z` restored it.
- Unmodified Vim `gg`, `dd`, and `u` deleted and restored the first line. `Escape` returned insert and visual modes to normal mode.
- `Ctrl+W` invoked **Close Active Item**. Zed requested confirmation for unsaved disposable edits; after saving, the same shortcut closed the item.

### Integrated terminal

The Zed command palette opened **Terminal Panel: Toggle**. The terminal started:

```text
ping -t 127.0.0.1
```

The `ping.exe` process was present before `Ctrl+C` and absent after it. The terminal then accepted and ran a sentinel command, which proves that control returned to the shell after the interrupt.
