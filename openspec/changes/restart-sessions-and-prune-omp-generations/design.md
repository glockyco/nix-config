## Context

`Updater.promote` swaps `current` and `previous` atomically. Generation directories live in `~/.local/share/omp-dev/generations/`, and each checkout is a worktree of `repository.git`. Nothing removes them. OMP's `/restart` re-executes `resolveCliEntryCmd()`, the running generation's absolute `cli.ts`, so it cannot change generations. The wrapped `omp` command resolves `current` at launch and passes `--extension <plugin> --plugin-dir <plugin>/lsp` before the operator's own arguments.

For every agent, Herdr reports its status (`idle`, `done`, `working`, `blocked`, `unknown`), its pane, and its session file. For every pane, `herdr pane process-info` reports the foreground processes with argv, which names the generation's `checkout`. `herdr pane read` returns the visible screen. `herdr agent prompt` refuses a blocked agent, and `herdr pane run` sends a command line to the pane's shell. Both hosts install Herdr from the flake.

Observed on 2026-09-28 with OMP 18.4.1: when the editor already held `unsent draft words`, `herdr agent prompt … /exit` produced the message `unsent draft words /exit`. The agent answered it as a message, and the session did not exit. An empty editor renders its last line as exactly `╰─`.

## Goals / Non-Goals

**Goals:**

- Move idle Herdr-managed sessions to a new selection without operator action and without modifying OMP.
- Keep only the generations needed for launch, rollback, and running sessions.
- Give an agent that runs the updater enough structured output to tell the operator what still needs attention.

**Non-Goals:**

- Restart sessions outside Herdr, or on another host.
- Interrupt work or discard input. Only idle sessions with empty editors restart.
- Run Nix garbage collection. NixOS and Determinate keep their schedules, and the operator can run `nix store gc` explicitly.
- Classify every process that pins a generation. The report gives process counts per retained generation.

## Decisions

### Restart through exit and resume in the same pane

For each candidate, the updater:

1. re-reads the agent status and continues only for `idle` or `done`;
1. reads the visible screen and continues only if the last line that starts with `╰─` is exactly `╰─`;
1. sends `/exit` with `herdr agent prompt`;
1. polls `pane process-info` until no foreground process names a generation, for up to 30 seconds;
1. runs `omp --resume <session-file>` with `herdr pane run`;
1. polls until the pane's foreground names the selected generation, for up to 60 seconds.

Resuming by session file avoids ID-prefix ambiguity. The editor check fails closed. A missing or changed editor line means the session is skipped, so an OMP interface change can only reduce restarts, never lose input.

Alternative: patch `/restart` to re-execute the wrapper. The owner rejected new OMP patches, and every patch refresh would have to carry it.

### Restart only sessions launched as plain `omp`

After the wrapper's `--extension` and `--plugin-dir` pairs, any remaining argv makes the session ineligible. Relaunching correctly requires OMP's flag table. For example, `--resume` takes an optional value, and a positional prompt would be sent again. Dropping arguments would silently change behavior such as `--approval-mode`. A session started with `--resume` or `--continue` also counts as custom. The operator restarts those after reading the report.

### Detect superseded sessions from the process

A session is superseded when a foreground process in its pane names `generations/<name>/checkout` and `<name>` differs from the selected generation. A pane whose argv names no generation is left alone.

### Exclude the invoking pane

The updater compares each pane with `HERDR_PANE_ID` from its own environment. An agent that runs the update procedure would otherwise end itself mid-report.

### Report schema

A successful update that changes the selection, a rollback, or a `--prune` prints:

```json
{
  "release": "…", "upstream": "…", "patchBase": "…", "patchTip": "…", "commit": "…", "system": "…",
  "sessions": {
    "herdr": "available" | "unavailable",
    "restarted": [{"pane": "w3:p2", "sessionFile": "…"}],
    "skipped": [{"pane": "w8:p1", "sessionFile": "…", "generation": "v18.2.11-…", "reason": "…"}]
  },
  "generations": {
    "removed": ["v18.1.13-…"],
    "current": "v18.4.1-…", "previous": "v18.2.11-…",
    "inUse": [{"generation": "v18.1.17-…", "processes": 10}]
  }
}
```

`--prune` omits the metadata fields and `sessions`. `reason` is one of `invoking`, `working`, `blocked`, `unknown`, `draft`, `editor-unrecognized`, `custom-arguments`, `no-session-file`, `exit-timeout`, and `relaunch-unconfirmed`. `restarted` and `skipped` cover only Herdr-managed sessions on superseded generations. A human-readable summary on standard error lists the skipped panes with their reasons. The unchanged-update path keeps printing the metadata alone.

The existing `omp-update` skill and the update procedure tell agents to relay every `skipped` entry, especially `invoking`, and every `inUse` generation. `invoking` names the agent's own session, which the operator must restart.

### Retention after restarts, and on demand

Cleanup runs after the restarts, so restarted sessions no longer pin their old generation. A generation is in use when any process's `ps -axo args` output contains its directory path. That works the same on Linux and macOS. Removal deletes the directory and runs `git worktree prune` on the shared repository. `--prune` takes the update lock and performs only this step.

### Herdr path through the pinned configuration

`package.nix` adds the Herdr executable path to the JSON configuration, and `load_config` validates it like `git` and `gh`. Every Herdr call has a timeout. A failing `herdr agent list` means Herdr is unavailable, which is not an error.

## Risks / Trade-offs

- \[The agent starts a turn between the checks and `/exit`\] → The editor was empty, so `/exit` arrives as a short message to a busy agent. The exit wait times out, and the pane is reported as `exit-timeout` without a relaunch.
- [The session leaves the pane between exit and relaunch] → `herdr pane run` types into whatever the shell shows. The relaunch runs only after the exit wait confirms that no generation process is in the foreground.
- [Pruning removes a generation that a process uses without naming it] → The launcher passes the checkout path explicitly, and workers inherit it. A process that uses the files without such a path is not expected.

## Migration Plan

1. Implement, run the package tests and release gates, and activate both hosts.
1. The first selection change or `--prune` removes superseded generations.

Rollback: revert and activate. Pruned generations are gone, but current, previous, and in-use generations are never pruned.
