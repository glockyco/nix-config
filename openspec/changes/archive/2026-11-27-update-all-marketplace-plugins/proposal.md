# Proposal

## Why

Only `personal@glockyco` updates by itself. The booking, Workbench and Obsidian plugins are upgraded by hand on each host, so they drift: on 2026-11-27 the Mac ran booking 0.8.1 after 0.9.0 was released, and Korolev ran the Workbench omp plugin 0.18.4 after 0.19.7. The Mac also registered two private marketplaces as SSH sources, which go through Secretive and wait for Touch ID, so an unattended upgrade hangs instead of failing, and nothing reported it.

## What Changes

- One shared fact declares the marketplace plugins that both hosts keep current: `personal@glockyco`, `booking@glockyco-booking`, `workbench@glockyco-workbench` and `obsidian@obsidian-skills`, each with its marketplace's GitHub source.
- The existing hourly user job on the Mac and on Korolev refreshes and upgrades every declared plugin instead of only the personal plugin. A failure of one plugin no longer stops the others, and the run exits nonzero when any failed.
- Each command runs non-interactively with a time limit, so a credential prompt or a stuck fetch becomes a logged failure instead of a hang.
- Before upgrading, the job checks the GitHub sign-in that Git's HTTPS credential helper uses and logs that `gh auth login` is needed when it is invalid.
- The job logs a marketplace registered with a source other than its declared GitHub source, with the command that fixes it. It does not change registrations itself.
- The README and the host guides list the declared plugins from the shared fact and drop the statement that other marketplace plugins stay manual.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `personal-plugin-updates`: the jobs keep every declared marketplace plugin current, run each command with a time limit, isolate failures per plugin, and report an invalid GitHub sign-in and mismatched marketplace sources.

## Impact

- `home/.chezmoidata/` gains the plugin declaration. `modules/roles/darwin/desktop/personal-plugin-updates.nix`, `windows/personal-plugin-upgrade.ps1`, `windows/Workstation.PluginUpdates.ps1` and their checks and tests change.
- `README.md`, `docs/operations/korolev-windows.md` and `docs/operations/dependency-updates.md` change. The personal desktop runs no update job and keeps its own instructions.
- Korolev needs a `chezmoi apply` to copy the new runner. The Mac needs a system switch.
- The Mac's two SSH-registered marketplaces are fixed by hand once. The job only reports them.
