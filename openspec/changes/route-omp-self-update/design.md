## Context

See proposal.md for motivation. `packages/personal-omp.nix` executes the configured external binary with immutable plugin arguments. Upstream's updater selects its target from `PATH`, which normally selects the Nix wrapper.

The accepted update contract currently requires the installer pipeline on WSL. This change replaces that routine operation, not bootstrap or recovery.

### Read-only spike

On 2026-09-06, the installed binary's `update --help` documented `--check` as non-installing. A child process with `$HOME/.local/lib/oh-my-pi` first on `PATH` resolved `omp` to `/home/user/.local/lib/oh-my-pi/omp`. Its `omp update --check` exited zero and reported current version 18.1.10 and available version 18.1.12.

This proves command resolution and release discovery only. It does not prove replacement: the check-only path does not exercise installation. No executable or repository implementation changed during the spike.

The upstream implementation inspected was `packages/coding-agent/src/cli/update-cli.ts` on [upstream main](https://github.com/can1357/oh-my-pi/blob/main/packages/coding-agent/src/cli/update-cli.ts). Its path-based target selection supports this approach; installed-release behavior still requires the real update gate.

## Goals / Non-Goals

**Goals:** Scope changed command resolution to one explicit update invocation. Preserve the existing executable guard and process exit behavior.

**Non-Goals:** No global `PATH` change, new updater command, source patch, activation-time update, plugin-manager migration, or Darwin update redesign.

## Decisions

- Add the dispatch inside the existing wrapper after its executable guard and before session plugin arguments. Generate it only for the existing WSL home-relative executable configuration.
- Match the leading `update` argument exactly. Do not implement a second OMP argument parser or intercept text supplied to normal sessions.
- Derive the executable directory from the configured target. Prepend it only in this branch, then `exec` that same executable with the original arguments.
- Leave Darwin and all other invocations on the existing path. Global precedence would allow nested OMP commands to bypass the immutable plugin setup.
- Keep upstream responsible for downloads, release selection, integrity checks, flags, and replacement. A custom installer wrapper would duplicate ownership without fixing the existing command.
- Reuse relevant checks in `flake.nix`. Replace affected source-text assertions with observable routing checks rather than pinning the new shell text.

## Risks / Trade-offs

- Upstream target detection can change → require a real update through the built wrapper, not just `--check`.
- A broad dispatch can bypass normal sessions → cover empty arguments, prompt text containing `update`, and nested command resolution.
- A global path override can bypass the plugin → keep the change inside the update branch and run the wrapped-session smoke.
- A binary update affects subsequent sessions outside Nix generations → retain the documented pinned installer recovery path and run browser verification.
- This host cannot provide native Darwin acceptance → preserve Darwin routing and require native checks before release acceptance.

## Migration Plan

1. Build the changed wrapper and run deterministic routing checks and repository release gates.
1. Run a real WSL update through the built wrapper from a disposable directory. Record observed versions and the updated target.
1. Run `verify-personal-omp`, the model-backed wrapped-session preview, and the managed-browser smoke with the candidate wrapper.
1. Review and merge before normal host activation. Confirm the default shell resolves the wrapper and repeat applicable activation checks.
1. If wrapper routing fails, restore the previous Nix generation. If the binary release fails, use the pinned installer recovery procedure instead.

Keep acceptance evidence with this change. Do not archive until every required gate passes.
