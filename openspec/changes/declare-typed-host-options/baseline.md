# Typed host options baseline

Captured from parent commit `cf0b5952860e1ed662b9ee6ae084652741b4a621` on 2026-09-04.

## Locked inputs

`flake.lock` SHA-256:

```text
bcf85fc5d7cddb6490638c8e9f1713c1fc9b6df5aab96a94fa854a9caa84a3e9
```

The lock file must keep this checksum throughout the change.

## Revision-independent system derivations

Both evaluations force `system.configurationRevision` to `typed-host-options-baseline` through `extendModules`:

```sh
nix eval --raw --impure --expr '
  let
    f = builtins.getFlake (toString ./.);
    force = f.inputs.nixpkgs.lib.mkForce;
    darwin = f.darwinConfigurations.macbook-pro.extendModules {
      modules = [{ system.configurationRevision = force "typed-host-options-baseline"; }];
    };
    nixos = f.nixosConfigurations.korolev.extendModules {
      modules = [{ system.configurationRevision = force "typed-host-options-baseline"; }];
    };
  in darwin.config.system.build.toplevel.drvPath
    + "\n"
    + nixos.config.system.build.toplevel.drvPath
    + "\n"
'
```

Two consecutive evaluations returned:

```text
/nix/store/7jyhmhg9ky49h1asr7j789v21djngpwk-darwin-system-26.05.c3e90c8.drv
/nix/store/qh2rfd9idccmxv07dbw47v6d5rpa6f97-nixos-system-korolev-26.05.20260814.02e0898.drv
```

The final revision must return these exact paths. If either differs, evaluate the changed options and run `nvd diff` on the host closures before accepting the change.

## Wrapper outputs

| System           | Output                                            | Wrapper SHA-256                                                    |
| ---------------- | ------------------------------------------------- | ------------------------------------------------------------------ |
| `aarch64-darwin` | `/nix/store/qiqycmg4phpaqi8scc1mgjkdqzs6kwsw-omp` | `6328b5f4c82b82cd91f686228577360d193d0f4bb4404259f2a997665eb9a732` |
| `x86_64-linux`   | `/nix/store/i7a3q6fz1m05nrv24rc5g41sjskbp22l-omp` | `0ea6f0a2de04abcae571737c72a4f940c2f2c1d11108ac1584203ba2a96e7484` |

The Darwin script was read from the derivation's `env.text` because the Linux machine cannot build `aarch64-darwin` dependencies before the remote builder change.

### `aarch64-darwin`

```sh
#!/nix/store/s6aq5vg89zwj44x1cfl8mj0k28d0cv05-bash-5.3p9/bin/bash
set -o errexit
set -o nounset
set -o pipefail

export PATH="/nix/store/0f773yv92q4wxjjvrwrqzq4pjr8pi8sv-marksman-2026-02-08/bin:/nix/store/qpziwcjwikfxk3nl45ayk3qrpw3v1wx5-nixd-2.9.1/bin:/nix/store/4rlznk06n8mwh6z58nvfn2gf28h3i46j-pyright-1.1.411/bin:/nix/store/z4azmmd0rk822sgqph0nrvva0s2j3ilp-roslyn-ls-5.7.0-1.26220.12/bin:/nix/store/0nxjqbzi2cwy134qaq4vb753kj5ss4ay-svelte-language-server-0.17.31/bin:/nix/store/xk9wmn7lnr9iqgfc9q7510h6yn4i2kwy-texlab-5.25.1/bin:/nix/store/8gzdzcspi58sia9f1p1bs9wg5ls6jbrw-typescript-language-server-5.3.0/bin:$PATH"

# Each flag is aimed at what only it provides. --extension loads the
# personal_commit extension, the skills, the rules, and the OpenSpec
# workflow commands. --plugin-dir loads the LSP overrides, and points at
# the scoped lsp/ root: aiming it at the package root would rescan
# commands/ and register every workflow command a second time under a
# store-derived name.
omp_bin="/opt/homebrew/bin/omp"
if [ ! -x "$omp_bin" ]; then
  # Keep variables literal so the displayed install command remains reusable.
  # shellcheck disable=SC2016
  printf 'oh-my-pi executable not found at %s.\nInstall it with:\n  %s\n' \
    "$omp_bin" 'brew install can1357/tap/omp' >&2
  exit 1
fi

exec "$omp_bin" --extension /nix/store/l1zkvlpmc2a74pw6a22b42v2ddg89726-personal-omp-plugin-0.1.0 --plugin-dir /nix/store/l1zkvlpmc2a74pw6a22b42v2ddg89726-personal-omp-plugin-0.1.0/lsp "$@"
```

### `x86_64-linux`

```sh
#!/nix/store/1sr8rmx4v0v994lkbzhwc1f0qr1gxxs9-bash-5.3p9/bin/bash
set -o errexit
set -o nounset
set -o pipefail

export PATH="/nix/store/z0d1x5x34rkp62kna38cv4rvglxq3vnb-marksman-2026-02-08/bin:/nix/store/d8lrd5pvij05fdh8aydp7mc496p8ia8p-nixd-2.9.1/bin:/nix/store/9nwhrai2q019wr8357al5im44qsg6cj7-pyright-1.1.411/bin:/nix/store/gfgqrwy19z7g1pimq7n13qf6px3dsh1n-roslyn-ls-5.7.0-1.26220.12/bin:/nix/store/f1q5wxryky6c1lrfr5jr1rxgykj3w2bg-svelte-language-server-0.17.31/bin:/nix/store/1cyr85x9msljsn77iicc9yxvbsia75x8-texlab-5.25.1/bin:/nix/store/kg0shj6lskykp61agp5g4ks3qymsbilr-typescript-language-server-5.3.0/bin:$PATH"

# Each flag is aimed at what only it provides. --extension loads the
# personal_commit extension, the skills, the rules, and the OpenSpec
# workflow commands. --plugin-dir loads the LSP overrides, and points at
# the scoped lsp/ root: aiming it at the package root would rescan
# commands/ and register every workflow command a second time under a
# store-derived name.
omp_bin="$HOME/.local/lib/oh-my-pi/omp"
if [ ! -x "$omp_bin" ]; then
  # Keep variables literal so the displayed install command remains reusable.
  # shellcheck disable=SC2016
  printf 'oh-my-pi executable not found at %s.\nInstall it with:\n  %s\n' \
    "$omp_bin" 'curl -fsSL https://omp.sh/install | PI_INSTALL_DIR="$HOME/.local/lib/oh-my-pi" sh -s -- --binary' >&2
  exit 1
fi

exec "$omp_bin" --extension /nix/store/h2a5dmh6cjxl3p3g1gjc7y4ndicarprh-personal-omp-plugin-0.1.0 --plugin-dir /nix/store/h2a5dmh6cjxl3p3g1gjc7y4ndicarprh-personal-omp-plugin-0.1.0/lsp "$@"
```

## Home Manager invariants

Both hosts evaluate:

```json
{"backupFileExtension":"hm-backup","useGlobalPkgs":true,"useUserPackages":true}
```

The ordered package-name lists were captured through `map (p: p.name)` at the parent commit. The final comparison uses `git+file://$PWD?rev=cf0b5952860e1ed662b9ee6ae084652741b4a621` as the baseline source.

## Binary-cache invariants

Both hosts evaluate:

```json
{
  "substituters": ["https://cache.numtide.com"],
  "trustedPublicKeys": ["niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="]
}
```
