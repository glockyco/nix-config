# Design

## Context

See proposal.md for motivation. Mac startup has separate non-interactive and interactive PATH handling, and the user launch agent selects OMP by absolute path. Nix and chezmoi must not install or modify the runtime.

## Goals / Non-Goals

Keep Tern OMP ahead of local tools in both shell modes, including after system startup changes PATH. Preserve the local tools directory and Tern application CLI. Do not activate configuration, delete the standalone binary, add wrappers or manage Tern runtime data.

## Decisions

Prepend the quoted Tern OMP bin directory in each existing Darwin desktop PATH assignment. Retain unique zsh path arrays and existing ordinary-tool order. Do not replace ~/.local/bin or link executables, because other tools still use that directory and Tern owns runtime updates.

Use the quoted Tern executable path for both launch-agent commands. The agent must not depend on interactive startup. Keep its scheduling, logs and fail-fast behavior unchanged.

Extend existing shell fixtures with competing OMP executables and assert Tern OMP, Tern CLI and local-tool resolution for non-interactive and interactive shells. Place the updater fixture at Tern's space-containing path and preserve success and failure tests.

State Tern ownership in current-state guidance and drop installer rollback instructions. No Tern version-selection mechanism has been established, so do not claim one.

## Risks / Trade-offs

Tern must have provisioned its managed OMP before a new shell or scheduled job can use it. No fallback or runtime bootstrap is added. Validate a separate branch checkout on the Mac without switching the live generation or applying to the real home. Keep the old executable until merge and user activation.
