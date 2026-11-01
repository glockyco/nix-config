# Design

## Context

The Darwin desktop role already uses launchd user agents. Windows settings converge through a PowerShell engine invoked before chezmoi applies user files. OMP remains installed and managed outside Nix and the engine.

## Goals / Non-Goals

Schedule only the personal plugin's supported manager commands. Do not update OMP, other plugins, running sessions or Nix dependencies.

## Decisions

Use a launchd user agent on macOS with the official executable under the configured home. Run at load and hourly, with stdout and stderr in Library/Logs.

Add a typed personal-plugin setting to the Windows engine rather than a separate installer or scheduler. Copy its runner to WindowsConfiguration so its task survives checkout changes. Register an unelevated InteractiveToken task for the current user with logon and hourly triggers. Compare the installed runner and task definition during dry runs.

The Windows runner rebuilds PATH from persisted user and machine values and resolves OMP there. It logs timestamped runs, command output and failures. Marketplace EPERM failures receive four attempts with short waits. Other failures stop immediately, and upgrade never follows a failed marketplace refresh.

## Risks / Trade-offs

Windows waits until the user is logged on. This is required because SSH sessions cannot reliably access OMP plugin files. A held marketplace handle can still exhaust the bounded retries, leaving a readable failure for the next hourly attempt.

Mac activation needs a password. Build and check the generation without running darwin-switch.
