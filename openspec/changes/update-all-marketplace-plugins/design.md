# Design

## Context

The Mac runs a launchd user agent whose shell runner Nix generates in `modules/roles/darwin/desktop/personal-plugin-updates.nix`. Korolev runs a scheduled task that the workstation engine registers and that executes `windows/personal-plugin-upgrade.ps1`, copied to `%LOCALAPPDATA%\WindowsConfiguration`. Both hard-code `glockyco` and `personal@glockyco`. Shared facts live in `home/.chezmoidata/*.toml`: Nix reads them with `builtins.fromTOML`, and chezmoi templates read them directly. Git over HTTPS gets GitHub credentials from `gh auth git-credential` on the Mac and from Git Credential Manager on Korolev. Both are set up with `gh auth login`. On the Mac, `gh` keeps its token in the login keychain, which only the logged-in GUI session can read: the launchd agent runs there (`LimitLoadToSessionType = "Aqua"`), while an SSH session sees the token as invalid. Remote maintenance on the Mac therefore runs in a Tern session. SSH on the Mac goes through Secretive, which needs Touch ID for every signature.

## Goals / Non-Goals

**Goals:**

- One declaration of the kept plugins, read by both hosts.
- A run that ends in bounded time and names its failures.

**Non-Goals:**

- Repairing registrations or signing in. The job reports, and the person fixes. Re-registering a marketplace changes OMP state that the plugin manager owns, and signing in needs the person anyway.
- Plannotator's npm-installed plugin, which stays pinned in the README's OMP block.
- Showing failures outside the log. A Workbench view of outdated plugins is a separate change in that repository.

## Decisions

### The declaration lives in `home/.chezmoidata/omp.toml`

Each `[[omp.plugins]]` entry names `plugin`, `marketplace` and `source` (`owner/repo`). Nix reads it into the Mac runner at build time. On Windows, a chezmoi template renders the list to `%LOCALAPPDATA%\WindowsConfiguration\omp-plugins.json`, which the runner reads. Alternative: a `plugins` array on the `personalPluginUpdate` resource in `windows/workstation.json`. Rejected because it would be a second copy of the Mac's list.

### Plugins run independently, in declaration order

For each plugin the runner refreshes its marketplace, then upgrades the plugin if the refresh succeeded. It records failures and continues, then exits 1 if any plugin failed. Korolev keeps its EPERM retries per marketplace. Alternative: stop at the first failure, as today. Rejected because one broken private repository would freeze every other plugin.

### Every command has a time limit and no input

Commands run with `GIT_TERMINAL_PROMPT=0` and `GIT_SSH_COMMAND="ssh -o BatchMode=yes"`. Each command is limited to five minutes: through `timeout` from Nix's coreutils on the Mac, and on Windows through a process wait that kills the process tree when the limit passes. A Secretive confirmation is an agent-side wait that `BatchMode` does not stop, so only the time limit ends it. The Windows task's `ExecutionTimeLimit` grows from 15 to 50 minutes, so four plugins with retries fit. `MultipleInstancesPolicy` stays `IgnoreNew`, which keeps hourly runs from overlapping.

### The sign-in check uses Git itself

Before the refreshes, the runner calls `git ls-remote --exit-code https://github.com/<source> HEAD` with the limits above for every declared source. A failure logs "Git cannot read https://github.com/<source>: run gh auth login -h github.com --web". Checking through Git covers both credential helpers. `gh auth status` would miss Korolev's Git Credential Manager. A failed check is logged but does not skip the refresh, so public marketplaces still update.

### The source check reads `omp plugin marketplace list`

The runner parses the command's `name  source` lines and compares each declared marketplace's source with its declared `owner/repo`. On a mismatch it logs `omp plugin marketplace remove <name>` and `omp plugin marketplace add <owner/repo>`, and it still runs that plugin's refresh. Alternative: read `~/.omp/marketplaces.json`. Rejected because that file is OMP's internal state, while the command is its interface. The command has no JSON output, so a change in its format shows up as a logged parse failure, not as silently skipped checks.

### Names stay

The launchd label, the task name `OMP personal plugin upgrade` and both log files keep their names, and so does the capability. Renaming them would leave stale registrations and logs on both hosts without changing behavior.

## Risks / Trade-offs

- The `omp plugin marketplace list` format changes. The runner then logs that it can't read the listing, and the checks cover the parser with the current output.
- A slow but healthy refresh exceeds five minutes. It fails visibly and runs again next hour. Refreshes take seconds today.
- Upgrading `obsidian@obsidian-skills` automatically pulls third-party changes into new sessions. The person chose this. A bad release is replaced by a newer one, never by editing the cache.

## Migration Plan

1. On the Mac, in a Tern session, remove `glockyco-booking` and `glockyco-workbench` and add them again as `glockyco/omp-booking` and `glockyco/obsidian-workbench`, then upgrade both plugins. Both hosts then match the declaration before the job checks it.
1. Merge, switch the Mac, and run `chezmoi apply` on Korolev, which copies the runner and re-registers the task.
1. Read both logs after the next run.

Rollback: revert the commit and apply again. The previous runner and task definition come back unchanged.
