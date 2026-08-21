## Why

Non-interactive commands sent to the MacBook Air inherit the workstation's interactive SSH multiplexing policy. Persistent control masters can keep harness-managed commands alive after the remote process exits, while the Air's non-interactive shell does not provide the Docker executable on `PATH`.

## What Changes

- Add a dedicated SSH host alias for unattended commands to the MacBook Air.
- Disable terminal allocation, prompting, connection multiplexing, and connection persistence for that alias while preserving the existing interactive `air` behavior.
- Preserve SSH stdin for protocol-driven tools such as `rsync`; command-only callers detach stdin when they do not supply input.
- Keep remote tool paths explicit at interfaces that already accept them instead of changing the Air's shell initialization.
- Add configuration checks and a live acceptance procedure for bounded command completion and remote Docker access.
- Document which alias operators and automation must use.

## Capabilities

### New Capabilities

- `batch-ssh`: Provides a deterministic, non-interactive SSH transport to the MacBook Air without changing interactive SSH behavior.

### Modified Capabilities

None.

## Impact

- Affects the Home Manager SSH configuration, its evaluation checks, and workstation operations documentation.
- Adds no package or service dependency.
- Requires automation that targets the Air, including Teralizer corpus export, to select the batch alias and provide the remote Docker executable explicitly.
