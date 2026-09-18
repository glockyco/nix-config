# Acceptance Evidence

## Static gates

- `nix fmt -- --fail-on-change` passed on 2026-09-18.
- `nix flake check --all-systems --print-build-logs` passed all 15 Linux-executed checks on 2026-09-18, including `checks.x86_64-linux.wslOpenCommand`.
- `openspec validate add-cross-platform-open-command --strict` passed on 2026-09-18.
- `nix build --print-build-logs .#checks.x86_64-linux.wslOpenCommand` passed after the implementation and after the Explorer status correction.
- The mutation probe renamed `wslpath`, confirmed that `wslOpenCommand` failed, restored `wslpath`, and confirmed that the check passed.
- After the Korolev-only clean cut, the focused WSL and Windows configuration checks passed, the full all-system flake check passed, and the rendered Windows artifact contained no `OpenTarget` files or resource.

## Korolev live smoke

- Activated NixOS system: `/nix/store/mqs9ajwkp1dlaz5dg5px6zsrq0i3vca4-nixos-system-korolev-26.05.20260903.a5cc6f2`.
- A fresh login shell resolved `open` to `/etc/profiles/per-user/user/bin/open`.
- `open`, `open 'directory with spaces'`, `open 'file with spaces.txt'`, and `open https://example.com` returned status 0.
- Windows showed Explorer windows for the current and spaced directories, a Zed window for the file, and a Zen Browser window titled `Example Domain` for the URI.
- No Linux graphical opener was used.
- The live smoke found that Explorer returns status 1 after accepted launches. The wrapper now normalizes Explorer statuses other than shell execution failures 126 and 127. The corrected static check and live smoke passed.

Rollback remains the previous NixOS generation through `sudo nixos-rebuild switch --rollback --no-reexec`.

## Change boundary

- No `wslu`, `wslview`, WSLg opener, shell alias, command interpreter, executable fallback, or activation-time Windows write was added.
- The native Windows command and Windows workstation baseline are outside this change.
- Commits `5b581a3`, `a38c063`, and `c3e2be3` contain the planning, WSL implementation, and README cleanup units. The final clean-cut commit removes the superseded native Windows unit from `bb75a9a`.
