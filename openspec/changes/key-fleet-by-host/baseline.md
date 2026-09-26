## Pinned-revision baseline

The implementation fills this comparison record before it edits code. Revision: `7723a53`. Probe: `/tmp/fleet-drv.nix`. The probe forces `system.configurationRevision` to 40 zeroes through `extendModules` and `lib.mkForce`.

| Host          | `config.system.build.toplevel.drvPath`                                                        |
| ------------- | --------------------------------------------------------------------------------------------- |
| `macbook-pro` | `/nix/store/415gil1nfc8ri1g9s05ycfbgxhp1n82g-darwin-system-26.05.c3e90c8.drv`                 |
| `korolev`     | `/nix/store/g49mzl623c5b30jb3y21m1v916byafvv-nixos-system-korolev-26.05.20260903.a5cc6f2.drv` |

During implementation, record the parent commit, `flake.lock` checksum, exact probe invocation, repeated evaluations, and both systems' wrapper, `herdr`, `openspec`, and plugin derivation paths here. Record each post-change comparison and explain each changed path with its closure diff. Do not infer missing measurements from the values above. A Mac evaluation of the Korolev derivation does not build it; Korolev or CI must perform that gate.
