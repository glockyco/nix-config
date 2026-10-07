# Evidence

Korolev was activated from `92c0834` (merged through PR #59) on 2026-10-07 as generation 51. `sudo nixos-rebuild switch --flake .#korolev` finished, `systemctl is-system-running` reported `running`, and generation 50 remains.

## Live dispatch

The checks ran with `open` resolved to the activated `/nix/store/6mjzb0ppzzv8faz8i4ckhzkf594qlx1x-open/bin/open`. Explorer windows were counted through `Shell.Application` before and after each dispatch.

| Command                                                          | Exit | Result                                       |
| ---------------------------------------------------------------- | ---- | -------------------------------------------- |
| `open 'https://example.com/?x=1&y=2'`                            | 0    | No Documents window opened (0 -> 0)          |
| `open` with a 367-character URI holding `?`, `&` and `%`-escapes | 0    | No Documents window opened (0 -> 0)          |
| `open` in a fresh temporary directory                            | 0    | One Explorer window opened at that directory |

Before the change, `explorer.exe` opened Documents for every query-string URI in the design's probes.
