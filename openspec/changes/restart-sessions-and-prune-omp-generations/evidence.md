# Evidence

## Korolev live acceptance on 2026-09-28

Host korolev. Herdr 0.8.2, OMP 18.4.1 (`v18.4.1-7d1j1oy5`) and 18.2.11 (`v18.2.11-3yndrh63`). Each run used the installed `omp-dev-update --rollback` from Herdr pane `w3:p1`. A disposable workspace held four OMP sessions (`wB:p1`–`wB:p4`) beside the operator's idle sessions `w2:pD`, `w8:p1`, and `w9:p1`.

### Before the change: manual draft probe

`herdr agent prompt … /exit` sent to a session whose editor held `unsent draft words` produced the user message `unsent draft words /exit`. The session did not exit. An empty editor renders its last line as `╰─`.

### Run 1 at `4d5d793`

- Rollback to v18.2.11. `wB:p1` and `wB:p2` were restarted. `wB:p3` was skipped as `draft`, and its editor still read `draft that must survive`. `wB:p4` was skipped as `working` during `sleep 75`. v18.4.1 was kept for 4 processes.
- Rollback to v18.4.1. `w9:p1` was restarted. `w8:p1` was skipped as `draft`, and the operator's unsent text was preserved. `w3:p1` was skipped as `invoking`. `w2:pD`, `wB:p1`, and `wB:p2` were skipped as `custom-arguments`: all three had been started with `--resume`. That defect was fixed by `05f69b1`.

### Run 2 at `05f69b1`

- Rollback to v18.2.11: `w9:p1` and `wB:p4` restarted. `wB:p3` skipped as `draft`.
- Rollback to v18.4.1: `w2:pD`, `w8:p1`, `wB:p1`, and `wB:p2` restarted, including the resumed sessions. `w9:p1` and `wB:p4`, restarted about 4 seconds earlier, were skipped as `no-session-file`. Herdr had not yet reported their session files. That defect was fixed by `ddbd54a`.

### Run 3 at `ddbd54a`

- Rollback to v18.2.11: `w2:pD`, `w8:p1`, `wB:p1`, and `wB:p2` restarted. `wB:p3` skipped as `draft`. v18.4.1 was kept for 3 processes.
- Rollback to v18.4.1, run immediately: `w2:pD`, `w8:p1`, `w9:p1`, `wB:p1`, `wB:p2`, and `wB:p4` restarted. Only `w3:p1` was skipped, as `invoking`. v18.2.11 was kept for this session's 4 processes.
- Afterwards, `herdr pane process-info` showed every session except `w3:p1` on v18.4.1. `omp-dev-update --status` reported v18.4.1.

Resumed sessions kept their session files and history, for example `wB:p1`'s `Reply with just: ok1` / `ok1`. A scan of every session file modified that day found no user message with `/exit` appended to other text. Every command exited 0.

## Korolev retention on 2026-09-28

Before the change, 12 superseded generations (about 34 GB) were removed by hand, followed by `nix store gc`, which freed 52.6 GiB. Afterwards, each run's report listed `removed: []`, because only current, previous, and in-use generations remained. The package tests cover removal of unused generations, removal of failed candidates, and worktree pruning.
