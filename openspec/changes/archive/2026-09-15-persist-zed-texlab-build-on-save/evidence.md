## Verification

Verified on 2026-09-15 against Zed 1.19.2 and TexLab 5.26.0 in the `saner2027-paper` WSL workspace.

- `openspec validate persist-zed-texlab-build-on-save --strict`: passed.
- `nix fmt -- --fail-on-change`: passed with no changed files.
- `nix build .#checks.x86_64-linux.windowsConfiguration --no-link`: passed.
- The rendered `zed-settings.json` contains `lsp.texlab.settings.texlab.build.onSave = true` and no repository path.
- The live Windows Zed settings contain the same build-on-save value.
- A Zed protocol trace showed that the Windows user setting reached TexLab as `build.onSave = true`.
- A real save in the visible Zed manuscript window updated `paper/build/main.pdf` from 12:24:47 to 12:42:08 and `paper/build/main.log` to 12:42:08.
- The rebuilt LaTeX log contains no LaTeX error, undefined control sequence, fatal error, emergency stop, multiply-defined-label warning, or undefined-reference warning.
