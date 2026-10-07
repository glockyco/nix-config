## Context

`add-cross-platform-open-command` chose direct `explorer.exe` execution for paths and URIs. Its live acceptance opened `https://example.com`, which has no query string. On 7 October 2026, a Tern sign-in URL dispatched through `open` opened the Documents folder instead of the browser. The following probes ran on Korolev from WSL. Each counted the Explorer windows at Documents before and after one dispatch:

| Dispatch                                                                                             | Result                 |
| ---------------------------------------------------------------------------------------------------- | ---------------------- |
| `explorer.exe https://example.com`                                                                   | Handler opened the URI |
| `explorer.exe https://example.com/path`                                                              | Handler opened the URI |
| `explorer.exe 'https://example.com/?x=1'`                                                            | Documents opened       |
| `explorer.exe 'https://example.com/?x=1&y=2'`                                                        | Documents opened       |
| `explorer.exe` with a 54-character URI holding `%`-escapes after `?`                                 | Documents opened       |
| `explorer.exe` with a 343-character URI after `?`                                                    | Documents opened       |
| `rundll32.exe url.dll,FileProtocolHandler` with a 330-character URI holding `?`, `&` and `%`-escapes | Handler opened the URI |

## Goals / Non-Goals

**Goals:** Every absolute URI reaches its registered Windows handler as one inert argument.

**Non-Goals:** Changing path dispatch, adding an `xdg-open` name, or opening Linux graphical applications.

## Decisions

### Dispatch URIs through the URL protocol handler

An absolute URI goes to `rundll32.exe url.dll,FileProtocolHandler <uri>`. The handler passes the URI to the Windows shell's registered protocol handler, as Explorer does for URIs without a query string. WSL passes the URI as one argument and no command interpreter parses it. The wrapper resolves `rundll32.exe` like `explorer.exe`, reports a missing executable as an unavailable boundary, preserves execution failures 126 and 127, and otherwise treats the call as dispatched.

Existing paths keep `wslpath -aw` and `explorer.exe`; Explorer opens them correctly and remains the folder view for directories.

Alternatives considered:

- **`cmd.exe /c start` and inline `Start-Process`**: rejected by the original design for their extra quoting boundaries; the reasons still hold.
- **Encoding `?` for Explorer**: changes the URI the handler receives.
- **`rundll32` for paths as well**: no failure motivates it, and directories would no longer open through Explorer's own entry point.

## Risks / Trade-offs

- \[`rundll32.exe` passes the rest of its command line to the handler. WSL quotes an argument that contains spaces.\] → An absolute URI holds no raw spaces; the behavior check pins the argument vector, and live acceptance repeats the failing query-string cases.
- [Registered URI handlers can launch installed applications.] → Unchanged: only an explicit absolute URI is dispatched.

## Migration Plan

Activate Korolev. Rollback restores the previous command with the previous generation.
