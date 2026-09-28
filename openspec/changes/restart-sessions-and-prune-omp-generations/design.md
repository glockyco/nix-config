## Context

`Updater.promote` swaps `current` and `previous` atomically. Generation directories live in `~/.local/share/omp-dev/generations/`, and each checkout is a worktree of `repository.git`. Nothing removes them. OMP's `/restart` re-executes `resolveCliEntryCmd()`, the running generation's absolute `cli.ts`, so it cannot change generations. The wrapped `omp` command resolves `current` at launch and passes `--extension <plugin> --plugin-dir <plugin>/lsp` before the operator's own arguments.

For every agent, Herdr reports its status (`idle`, `done`, `working`, `blocked`, `unknown`), its pane, and its session file. For every pane, `herdr pane process-info` reports the foreground argv, which names the generation's `checkout` path. `herdr agent prompt` refuses a blocked agent, and `herdr pane run` sends a command line to a pane's shell. Both hosts install Herdr from the flake.

## Goals / Non-Goals

**Goals:**

- Move idle Herdr-managed sessions to a new selection without operator action and without modifying OMP.
- Keep only the generations needed for launch, rollback, and running sessions.

**Non-Goals:**

- Restart sessions outside Herdr, or on another host.
- Interrupt work. Only idle sessions restart.
- Run Nix garbage collection. NixOS and Determinate keep their schedules, and the operator can run `nix store gc` explicitly.

## Decisions

### Restart through exit and resume in the same pane

For each candidate, the updater:

1. re-reads the agent status and continues only for `idle` or `done`;
1. sends `/exit` with `herdr agent prompt`, which rejects a blocked agent;
1. waits until the pane's foreground process no longer runs a generation;
1. runs `omp --resume <session-file> <operator arguments>` with `herdr pane run`.

The operator arguments are the original argv after the wrapper's `--extension` and `--plugin-dir` pairs, without any earlier `--resume`, `-r`, `--continue`, or `-c` and their values. Resuming by session file avoids the ambiguity of an ID prefix.

Alternative: patch `/restart` to re-execute the wrapper. The owner rejected new OMP patches, and a patch would also have to be carried through every future patch refresh.

### Detect superseded sessions from the process, not from Herdr metadata

A session is superseded when its pane's foreground argv names `generations/<name>/checkout` and `<name>` is not the selected generation. A pane whose argv names no generation is left alone. That covers another installation, a shell, or an OMP launched outside the updater.

### Exclude the invoking pane

The updater compares each pane with `HERDR_PANE_ID` from its own environment. The session that runs the update, for example an agent following the update procedure, would otherwise end itself mid-report.

### Restarts never fail the update

Selection is the contract of the command. A timeout, a Herdr error, or a session that does not exit is listed in the output, and the command still exits 0 after a successful selection. The residual race is an agent that starts a turn between the status read and `/exit`. Then `/exit` arrives as input to a busy agent. The wait step times out, and the updater reports the pane without running `omp` into it.

### Retention after restarts, and on demand

Cleanup runs after the restarts, so restarted sessions no longer pin their old generation. A generation is in use when any process argv contains its directory path. The scan uses `ps -axo args` on both platforms, so it works without `/proc`. Removal deletes the directory and runs `git worktree prune` on the shared repository. `--prune` takes the update lock, performs only this step, and never restarts sessions, because a restart belongs to the selection change that made sessions stale.

### Herdr path through the pinned configuration

`package.nix` adds a `herdr` executable path to the updater's JSON configuration, and `load_config` validates it like `git` and `gh`. No `PATH` lookup takes place. A missing server socket is the "Herdr unavailable" case, not an error.

## Risks / Trade-offs

- [An agent's input box holds unsent text] → `herdr agent prompt` pastes `/exit` into the editor. OMP runs the slash command only if the box was empty, and otherwise the text is submitted as a message. Mitigation: the exit wait times out, and the pane is reported without a relaunch. Implementation must verify OMP's behavior with a draft present and, if it is unsafe, skip panes whose editor is non-empty.
- \[Relaunch loses shell-level context such as exported variables set before the original `omp`\] → The pane's shell keeps its environment, and the relaunch runs in that same shell. Arguments are preserved from argv.
- [Pruning removes a generation that a detached process still needs] → The argv scan covers every process of the user. A process that uses the files without naming them in argv is not expected, because the launcher passes the checkout path explicitly.

## Migration Plan

1. Implement, run the package tests and the release gates, and activate both hosts.
1. The first update or `--prune` removes today's superseded generations.

Rollback: revert and activate. Pruned generations are gone, but any still needed are current, previous, or in use, and those are never pruned.
