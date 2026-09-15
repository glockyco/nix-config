## Context

Zed's Windows client starts TexLab inside the native WSL workspace. In the observed Zed 1.19.2 session, the remote LaTeX extension ignored `lsp.texlab.settings` from the repository's `.zed/settings.json`, although it applied the project-local binary override. The same extension passed the Windows user-level TexLab settings correctly. The Windows configuration already converges selected values into `%APPDATA%\Zed\settings.json` while preserving Zed-owned state.

## Goals / Non-Goals

**Goals:**

- Persist the verified user-level TexLab build-on-save setting through Windows configuration applies.
- Keep LaTeX commands and output paths in the project that owns them.
- Avoid previewer selection as part of this repair.

**Non-Goals:**

- Configure forward or inverse PDF search.
- Add a background watcher or wrapper script.
- Change the Zed or TexLab package versions.

## Decisions

Declare only `lsp.texlab.settings.texlab.build.onSave = true` in the Windows Zed overlay. The shared Zed settings remain platform-neutral because the demonstrated failure is specific to the Windows client with a WSL remote workspace.

Keep the paper's `.latexmkrc` and root marker in the paper repository. TexLab's default `latexmk` command then resolves the root document and lets the project define its output directory and bibliography environment.

Verify both layers. Nix evaluation must show the desired user setting in the rendered Windows artifact. A live Zed protocol trace must show `onSave: true`, followed by a save that updates the project PDF.

## Risks / Trade-offs

The setting applies to every LaTeX project opened by this Windows Zed installation. This is intentional: build-on-save is editor policy, while each project still controls the build itself. Projects that must not build automatically can override the setting if Zed fixes project-local workspace configuration propagation.
