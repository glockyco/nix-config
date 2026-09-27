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

## Host registry and package migration

After the host registry and package/check cutover, the pinned probe returned
`/nix/store/nyv3902mvw9vfmhr21s9ay4a33f053c0-darwin-system-26.05.c3e90c8.drv`
and `/nix/store/gwmdxyacsdf8sg9fx5462jkx86x7jfxl-nixos-system-korolev-26.05.20260903.a5cc6f2.drv`.
After fixing the Python wrapper's quoted `--config` argument, it returned
`/nix/store/y2fwxxcapvsdkf2zlcc17w92sygdxf0g-darwin-system-26.05.c3e90c8.drv`
and `/nix/store/3fnxzzd9yyc8hq6rmf0qbb1rjhfg17g4-nixos-system-korolev-26.05.20260903.a5cc6f2.drv`.
The wrapper, Herdr, OpenSpec, and plugin derivations remained identical to
their pre-migration paths on both systems. The Windows output remained
`/nix/store/sfyngvylyfv8kl7b18dmdr25aqf3bw8j-windows-workstation-configuration`.
The policy remained `/nix/store/ydbn9dyb204vbmascj5lc2ci7a3sw74p-tailnet-policy`;
its `policy.hujson` SHA-256 is
`151e3fd8cb9e0b26de7aea26c5ca98167bfb0998fcf5fde6364aee4e288c4279`.

## Gated lock experiment and final comparison

`llm-agents.inputs.flake-parts.follows = "flake-parts"` removed the duplicate
`flake-parts_3` lock node. The former `flake-parts_4` became `_3`; no locked
revision changed. The new `flake.lock` SHA-256 is
`f0d738d46e2fb144cae9e471f53a89f2c1a4772f9b65cd72f6bb44b983ef2871`.
The pinned system, wrapper, Herdr, OpenSpec, and plugin paths matched the
pre-experiment measurements on both systems.

After treefmt normalized the moved sources, the final
`nix eval --impure --json -f /tmp/fleet-snapshot.nix` returned:

| Host          | Final pinned `config.system.build.toplevel.drvPath`                                           |
| ------------- | --------------------------------------------------------------------------------------------- |
| `macbook-pro` | `/nix/store/5yif3pzimw7gk54pxnmz2i9868zrqd9c-darwin-system-26.05.c3e90c8.drv`                 |
| `korolev`     | `/nix/store/gm6nyljbwwrlnylcdp6mg0ck2sh65baj-nixos-system-korolev-26.05.20260903.a5cc6f2.drv` |

The four selected package derivations for both systems still match the
pre-migration table. The Mac command
`nix run nixpkgs#nvd -- diff /nix/store/7ykhsrnm6ij5bl9ry3hrlfrlkwgmqpg5-darwin-system-26.05.c3e90c8 /nix/store/k6n3wj7cpmdksg1vyy3r6swpqj0lcc1q-darwin-system-26.05.c3e90c8`
reported one version addition (`omp-dev-update` 0.1.0) and removal of the
standalone `omp-dev-update.py` source. Its closure changed from 5,855 to
5,854 paths (+14, -15, +153.8 KiB). Python packaging and source relocation
explain the Mac path change; no unrelated package version changed.

`nix run nixpkgs#nix-diff -- /nix/store/g49mzl623c5b30jb3y21m1v916byafvv-nixos-system-korolev-26.05.20260903.a5cc6f2.drv /nix/store/gm6nyljbwwrlnylcdp6mg0ck2sh65baj-nixos-system-korolev-26.05.20260903.a5cc6f2.drv`
compares the Korolev derivations without a build. Every difference descends
from one cause: the input derivation `omp-dev-update` became
`omp-dev-update-0.1.0` in `home-manager-path` and in `verify-personal-omp`,
whose script names the new updater store path. The remaining differing
derivations (`user-environment`, `home-manager-files`, `home-manager-generation`,
`unit-home-manager-user.service`, `system-units`, `etc`, `activate`) only carry
those two inputs upward. `tailnet-builder-check`, `nix.buildMachines`, the SSH
client configuration, and every other system derivation are identical. Owner
task 7.5 still records the built closure on Korolev.

## Mac repository gates

| Command                                                         | Exit | Key evidence                                                                                                                                                                                                       |
| --------------------------------------------------------------- | ---- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `nix fmt -- --fail-on-change`                                   | 0    | `formatted 1 files (0 changed)` after formatting the migration. A temporary unused Python local failed `ruff-check` with `F841`; removal restored the passing gate.                                                |
| `nix flake check --print-build-logs`                            | 0    | `Ran 27 tests ... OK` for the packaged updater; `checks.aarch64-darwin.treefmt`, the generated Mac system/home gates, the wrapper checks, and policy checks passed. Linux was omitted as incompatible on this Mac. |
| `nix run .#check-darwin-build-plans`                            | 0    | `42 outputs, none reaching a forbidden source build.`                                                                                                                                                              |
| `nix build .#darwinConfigurations.macbook-pro.system --no-link` | 0    | Built the Darwin configuration without activation.                                                                                                                                                                 |
| `openspec validate key-fleet-by-host --strict`                  | 0    | `Change 'key-fleet-by-host' is valid`.                                                                                                                                                                             |

The development-shell hook smoke ran `nix develop --command lefthook version`
and returned `2.1.5`; the installed `.git/hooks/pre-commit` invokes lefthook.

## CI evidence

PR #44 (`refactor/fleet-roles-programs` at `7903d59`) ran the `check` workflow (https://github.com/glockyco/nix-config/actions/runs/36333360593). `check (ubuntu-latest)` passed in 5m58s with Korolev's declared Nix and built every `x86_64-linux` check, including the Korolev system and home generation. `check (macos-15)` passed in 13m34s. The `tailnet-policy` `test` job passed.
