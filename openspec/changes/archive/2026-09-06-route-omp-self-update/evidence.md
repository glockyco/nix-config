# Update routing acceptance

## WSL routing and binary update — 2026-09-06

- Implementation checkpoint: `1792cdf`.
- `nix build .#personal-omp .#checks.x86_64-linux.personalOmpRouting --no-link --print-out-paths --print-build-logs` passed.
- Candidate wrapper: `/nix/store/xv3pbps4k9iaplaxqf8fp9cmxp9b2gn8-omp/bin/omp`.
- Routing regression passed: original update arguments, exit status 23, paths with spaces, missing executable, normal sessions, ACP, nested resolution, and unchanged absolute-target routing.
- The candidate wrapper's real `update` command installed 18.1.12 over 18.1.10 at `/home/user/.local/lib/oh-my-pi/omp`.
- Updater verification and the installed file's SHA-256 agreed: `f5431008f71d2f3971617205cfce9cb227c1d135665930088244c76d86b2fb42`.
- `verify-personal-omp` reported OMP 18.1.12, plugin `/nix/store/x2bq1ds306bni8y869w5gdcfk2g0zj19-personal-omp-plugin-0.1.0`, and `omp: current (v8)`.
- The candidate wrapper's `--version` reported 18.1.12.
- `nix fmt` changed no files; implementation commit hooks passed.

## WSL wrapped-session and browser smoke

The terminal-backed fresh session completed the requested `personal_commit` preview and quoted the active personal policy. Its skill read resolved to the immutable plugin above, but its final response did not identify the plugin source. A second fresh session read the candidate wrapper and plugin manifest, reported that source as `@glockyco/personal-omp-plugin` version 0.1.0, quoted the loaded policy, and completed the exact preview successfully. The disposable repository remained clean with zero commits.

The managed browser opened `https://example.com/`, reported the title and heading `Example Domain`, captured `/tmp/omp-sshots-1575400e649c9402.webp`, and closed successfully. The screenshot was visually inspected. No loader error occurred. An earlier non-PTY smoke launch waited for piped stdin; it was stopped before the terminal-backed run.

## Cross-platform routing and Homebrew update — 2026-09-06

- Rebased the WSL implementation checkpoint onto the Mac's seven retained commits; its current commit is `2cea737`. History integration used rebase, not a merge commit.
- Cross-platform implementation checkpoint: `0c51407`.
- Wrapper and routing-check builds passed on `x86_64-linux` and the native `aarch64-darwin` builder. The first fixture run failed because its formula lacked a `bin` directory; the corrected fixture passed on both systems.
- WSL candidate: `/nix/store/qxacx5vigd43gh73xlilm5gqin25dy8c-omp/bin/omp`. Its `update --check` reported 18.1.12 and already current.
- Darwin candidate: `/nix/store/s81h51dvwaxrx76yb677nqn96j1fckil-omp/bin/omp`.
- The Mac already had 18.1.12. The candidate's `update --force` explicitly reported `Updating Homebrew formulae...`, `Updating via Homebrew...`, and `Reinstalling can1357/tap/omp`.
- Homebrew reinstalled `/opt/homebrew/Cellar/omp/18.1.12`; OMP verified 18.1.12 afterward. `brew list --versions omp` reported `omp 18.1.12`.
- `verify-personal-omp` reported OMP 18.1.12, plugin `/nix/store/h6mjqcm3rpsj9pdxzn07n9rjbn84f132-personal-omp-plugin-0.1.0`, and `omp: current (v8)`.
- The candidate's subsequent `update --check` reported already current.

The native Mac session read the candidate wrapper and plugin manifest, reported the immutable extension path above, quoted the loaded commit policy, and completed the exact `personal_commit` preview. Its disposable repository remained clean with zero commits. The builder key rejected a PTY request; the successful session used its existing batch-only SSH boundary with stdin closed. No SSH policy changed.

## Release gates — 2026-09-06

- Linux: `nix fmt -- --fail-on-change` passed without changes. `nix flake check --all-systems --print-build-logs` evaluated both systems and completed the Linux checks successfully.
- Mac: all native gates ran in `/tmp/nix-config-omp-c3034f0` at commit `c3034f0`, transferred as an incremental Git bundle. The working Mac checkout was not changed.
- Native `nix fmt -- --fail-on-change` and `nix flake check --print-build-logs` passed.
- Native `nix run .#check-darwin-build-plans` reported `35 outputs, none reaching a forbidden source build`.
- Native `nix build .#darwinConfigurations.macbook-pro.system --no-link --print-out-paths` passed and produced `/nix/store/1msbdrln56sp1d7n9s4792y6ndvya7i4-darwin-system-26.05.c3e90c8`.
- `openspec validate route-omp-self-update --strict` passed.

## WSL activation — 2026-09-06

The owner authorized activation. `sudo nixos-rebuild switch --flake .#korolev` activated committed revision `f680cef` successfully as system generation 20. Previous generations, including generation 19, remain available.

The selected system is `/nix/store/sxb73z7x3lqh9ps38j1m0hxk7799m6vh-nixos-system-korolev-26.05.20260903.a5cc6f2`. Activation output and the Home Manager journal showed successful configuration activation and Herdr reconciliation. `systemctl is-system-running` reported `running`, with no failed units.

A fresh `zsh -lic` session resolved `omp` to `/etc/profiles/per-user/user/bin/omp`. Plain `omp update --check` reported 18.1.12 and already current. `verify-personal-omp` reported the immutable plugin and `omp: current (v8)`.

A fresh session launched through the normal login-shell command resolved the wrapper to `/nix/store/qxacx5vigd43gh73xlilm5gqin25dy8c-omp/bin/omp`. It verified the immutable plugin manifest and personal policy and completed the exact commit preview. The disposable repository remained clean with zero commits.

The same session opened the managed browser at `https://example.com/`, reported `Example Domain`, captured `/tmp/omp-sshots-1575474761d137d1.webp`, and closed the browser. The screenshot was visually inspected. No tool or loader error was reported.

## Mac activation — 2026-09-06

The clean Mac checkout at `/Users/glockyco/.config/nix-darwin` was advanced to `f680cef` through a bundle fetch and rebase. No remote push or merge commit was used. The owner performed the password-authorized activation and confirmed that the supplied activation, verifier, and `omp update --check` procedure worked. This is owner-reported acceptance; those commands were not repeated remotely.

A subsequent fresh session launched through the normal Mac login-shell `omp` command resolved `/nix/store/s81h51dvwaxrx76yb677nqn96j1fckil-omp/bin/omp`. It verified the immutable plugin manifest at `/nix/store/h6mjqcm3rpsj9pdxzn07n9rjbn84f132-personal-omp-plugin-0.1.0`, quoted the loaded personal commit policy, and completed the exact `personal_commit` preview. The disposable repository remained clean with no commits before and after the preview.

All change acceptance tasks are complete.
