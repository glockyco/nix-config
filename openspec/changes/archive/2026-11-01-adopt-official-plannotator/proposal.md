# Proposal

## Why

Annotation moves from the personal plugin's adapter to Plannotator's own OMP plugin, `@plannotator/pi-extension`, which answers Ask AI from the session, lets agents open reviews and offers a picker of recent replies. omp-agent-setup 0.10.0 drops the adapter, so the hosts have to install the official plugin, and its sharing default has to be turned off as the adapter did.

## What Changes

- Both hosts install `@plannotator/pi-extension` at a pinned version with OMP's plugin manager, by the documented command.
- chezmoi sets `share` to `disabled` in `~/.plannotator/config.json` and keeps the file's other settings.
- The visual-feedback and maintenance specs drop the adapter's requirements. The command-line tool stays for the terminal and the Inbox.
- The README, the Korolev runbook and the update runbook describe the plugin and its advancement.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `omp-visual-feedback`: the official plugin and the sharing setting replace the adapter's requirements.
- `plannotator-maintenance`: updates are checked with the official plugin's commands, without the adapter's cancellation contract.

## Impact

`home/dot_plannotator/modify_config.json`, the README's OMP section, `docs/operations/korolev-windows.md` and `docs/operations/dependency-updates.md`. No Nix package changes.
