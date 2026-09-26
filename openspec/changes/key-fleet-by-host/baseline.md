## Pinned-revision baseline

The implementation fills this comparison record before it edits code. Revision: `7723a53`. Probe: `/tmp/fleet-drv.nix`. The probe forces `system.configurationRevision` to 40 zeroes through `extendModules` and `lib.mkForce`.

| Host          | `config.system.build.toplevel.drvPath`                                                        |
| ------------- | --------------------------------------------------------------------------------------------- |
| `macbook-pro` | `/nix/store/415gil1nfc8ri1g9s05ycfbgxhp1n82g-darwin-system-26.05.c3e90c8.drv`                 |
| `korolev`     | `/nix/store/g49mzl623c5b30jb3y21m1v916byafvv-nixos-system-korolev-26.05.20260903.a5cc6f2.drv` |

During implementation, record the parent commit, `flake.lock` checksum, exact probe invocation, repeated evaluations, and both systems' wrapper, `herdr`, `openspec`, and plugin derivation paths here. Record each post-change comparison and explain each changed path with its closure diff. Do not infer missing measurements from the values above. A Mac evaluation of the Korolev derivation does not build it; Korolev or CI must perform that gate.

## Before implementation

Parent commit: `61f6589783c316d20b72958931fd958425e255e1`.
`sha256sum flake.lock`: `12db17af03985adad06a77a34eb76246af8cadf5eefe472b86d8bafa5f795a55`.
Commands: `nix eval --impure --json -f /tmp/fleet-drv.nix` and
`nix eval --impure --json -f /tmp/fleet-snapshot.nix`. The latter evaluates the
same pinned `extendModules` expression and the wrapper, Herdr, OpenSpec, and
plugin `drvPath` for each system. Two consecutive snapshot evaluations gave
identical values; the exact system probe also matched both paths above.

| Host          | Wrapper                                               | Herdr                                                         | OpenSpec                                                          | Plugin                                                                      |
| ------------- | ----------------------------------------------------- | ------------------------------------------------------------- | ----------------------------------------------------------------- | --------------------------------------------------------------------------- |
| `macbook-pro` | `/nix/store/2phmwnldaazd4c9n96ylgm8ny9h54lfk-omp.drv` | `/nix/store/ykgjlzzdnzmyzjri0pykswvzgy0h6ddi-herdr-0.8.2.drv` | `/nix/store/9vc3jfqh5rajc9lrhni4307jm7nf2xjm-openspec-1.12.0.drv` | `/nix/store/1cyv5p4i1nq88jb2h6211jjhcf0nny3x-personal-omp-plugin-0.1.0.drv` |
| `korolev`     | `/nix/store/6f16w3x0mj390xcdbcv0arbywbbivy86-omp.drv` | `/nix/store/f0fggh2a3yck94f5gsskyzpvs7k3dfgi-herdr-0.8.2.drv` | `/nix/store/20yq76v63djy9kcdnlpy7fcc63pmdx0a-openspec-1.12.0.drv` | `/nix/store/q7ywbmksq3dp0x0qbax84b9y8r1v95fi-personal-omp-plugin-0.1.0.drv` |

## Flake output split

After the output families moved to `flake-modules/`, the exact
`nix eval --impure --json -f /tmp/fleet-drv.nix` probe returned both baseline
system paths unchanged. `nix flake show --json` returned an output inventory
identical to the pre-split inventory, including each package and check name.
