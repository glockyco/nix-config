## Context

See `proposal.md` for motivation. Zed loads user bindings after its default and Vim keymaps, so a user binding at the same context level takes precedence. The current Windows layer converges `%APPDATA%\Zed\settings.json` as a subset because Zed writes interface state there. It does not manage `%APPDATA%\Zed\keymap.json`.

The reported conflict is observable in Zed's keymap editor. For `Ctrl+C`, the Vim source installs different actions for visual, insert, replace, operator, waiting, and literal modes. Zed's documented user-keymap precedence is the supported override mechanism.

## Goals / Non-Goals

**Goals:**

- Make one predictable Windows-first `Ctrl` layer for full text editors.
- Keep the useful modal Vim language on unmodified keys.
- Make the keymap reviewable and reproducible through the Windows configuration artifact.
- Avoid changing terminal and panel shortcuts.

**Non-Goals:**

- Reproduce Vim or VS Code keymaps completely.
- Customize `Alt`, function, navigation, or unmodified Vim keys.
- Change macOS Zed shortcuts.
- Preserve ad hoc edits to the managed Windows keymap.

## Decisions

### Manage `keymap.json` as a complete file

Add a separate Windows file resource for `%APPDATA%\Zed\keymap.json`. Use complete-file ownership because the keymap is personal policy, not application-generated interface state. The rendered review output includes the same JSON.

The settings resource remains a subset merge. Combining both policies in one merge helper would hide their different ownership contracts.

### Scope overrides to full editors

Use `Editor && mode == full` for the standard bindings. User bindings load after built-in Vim bindings, so this context restores the selected actions in every Vim mode without affecting terminals, menus, project panels, agent inputs, or short embedded editors.

Use two ordered binding blocks where an action can decline to run. The first maps the key to `null`; the second maps it to the selected action. This prevents propagation back to a lower-precedence Vim action.

### Restore a curated Windows and VS Code control layer

Declare these direct bindings with Zed's existing Windows actions:

| Key      | Action                       |
| -------- | ---------------------------- |
| `Ctrl+A` | Select all                   |
| `Ctrl+B` | Toggle the left dock         |
| `Ctrl+C` | Copy                         |
| `Ctrl+D` | Select the next occurrence   |
| `Ctrl+E` | Quick open                   |
| `Ctrl+F` | Find                         |
| `Ctrl+G` | Go to line                   |
| `Ctrl+H` | Replace                      |
| `Ctrl+I` | Show signature help          |
| `Ctrl+J` | Toggle the bottom dock       |
| `Ctrl+L` | Select line                  |
| `Ctrl+N` | New file                     |
| `Ctrl+O` | Open files                   |
| `Ctrl+P` | Quick open                   |
| `Ctrl+Q` | Quit Zed                     |
| `Ctrl+R` | Open recent projects         |
| `Ctrl+S` | Save                         |
| `Ctrl+T` | Project symbol search        |
| `Ctrl+V` | Paste                        |
| `Ctrl+W` | Close the active editor item |
| `Ctrl+X` | Cut                          |
| `Ctrl+Y` | Redo                         |
| `Ctrl+Z` | Undo                         |

Keep standard modified forms such as `Ctrl+Shift+P`, `Ctrl+Shift+S`, `Ctrl+Tab`, and `Ctrl+Shift+Tab` on the base keymap. They are not replaced by Vim today.

Map bare `Ctrl+K` to `null` in the full-editor context. Longer base-keymap sequences such as `Ctrl+K Ctrl+S` remain active and take precedence as complete sequences. This removes Vim digraph input while retaining the standard chord namespace.

Map Vim-only single-key controls with no selected Windows action to `null`: `Ctrl+[`, `Ctrl+]`, `Ctrl+^`, `Ctrl+M`, and `Ctrl+U`. `Escape` replaces the removed mode-change and cancellation aliases. Keep no Vim-specific single-key `Ctrl` binding in a full editor.

### Verify behavior in Zed, not only rendered JSON

Repository checks prove that the rendered resource owns the intended file and contains the expected contexts and actions. Live acceptance opens a full editor in the Windows Zed application and exercises normal, visual, and insert modes. It confirms copy, paste, select all, undo, find, close, an unmodified Vim edit, `Escape`, and one `Ctrl+K` chord. It also confirms that `Ctrl+C` still reaches an interrupt in the integrated terminal.

## Risks / Trade-offs

The policy intentionally removes Vim muscle memory such as `Ctrl+V` for visual-block mode, `Ctrl+A` and `Ctrl+X` for number changes, `Ctrl+R` for redo, and `Ctrl+W` pane commands. Equivalent unmodified Vim commands or Zed shortcuts remain available, but users who expect those control bindings must relearn them.

Zed action identifiers can change upstream. The repository check catches declaration drift only when its assertions change; the live apply gate catches an action that no longer resolves.

Complete-file ownership means Zed keymap-editor changes are temporary. The next Windows apply restores the reviewed policy. This is deliberate because merging keymap arrays cannot identify ownership safely.
