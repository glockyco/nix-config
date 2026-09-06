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

## Remaining acceptance

The terminal-backed fresh session completed the requested `personal_commit` preview and quoted the active personal policy. Its skill read resolved to the immutable plugin above, but its final response did not identify the plugin source. A second fresh session read the candidate wrapper and plugin manifest, reported that source as `@glockyco/personal-omp-plugin` version 0.1.0, quoted the loaded policy, and completed the exact preview successfully. The disposable repository remained clean with zero commits.

The managed browser opened `https://example.com/`, reported the title and heading `Example Domain`, captured `/tmp/omp-sshots-1575400e649c9402.webp`, and closed successfully. The screenshot was visually inspected. No loader error occurred. An earlier non-PTY smoke launch waited for piped stdin; it was stopped before the terminal-backed run.

Native release gates, review, merge, and activation are not complete. The default shell still uses the previously activated wrapper.

The user requested macOS `omp update` support during implementation. Native SSH access succeeds, and `brew --prefix can1357/tap/omp` reports `/opt/homebrew/opt/omp`. The planned Darwin exclusion needs revision before implementation.
