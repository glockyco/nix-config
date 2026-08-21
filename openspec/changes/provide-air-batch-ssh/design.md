## Context

See `proposal.md` for motivation and `specs/batch-ssh/spec.md` for the behavior contract.

The workstation's `Host *` policy enables `ControlMaster auto` with a one-hour `ControlPersist` interval because Git and interactive clients benefit from connection reuse. The existing `air` endpoint inherits that policy. OMP history shows that otherwise identical remote commands complete in about one second when multiplexing and persistence are disabled.

The Air's non-interactive shell does not resolve Docker from `PATH`. Teralizer's corpus export already accepts a deployment-specific remote Docker executable and uses SSH for both commands and `rsync`. The Air is temporary university equipment. Its SSH entries must be removed together during the existing return procedure rather than turning it into permanent fleet infrastructure.

## Goals / Non-Goals

**Goals:**

- Keep the Air's host identity and account in one declarative source.
- Give unattended commands and transfer tools a transport that cannot create or reuse persistent SSH masters.
- Preserve SSH standard streams for `rsync` and other protocol-driven clients.
- Make direct command completion, failure propagation, transfer, and remote Docker discovery reproducible acceptance checks.

**Non-Goals:**

- Change global SSH behavior or the existing interactive `air` endpoint.
- Modify shell initialization or install tools on the Air.
- Hide an unbounded remote workload behind connection-establishment settings.
- Make the Air a deployment target, batch worker, or permanent fleet member.

## Decisions

### Add a separate `air-batch` host alias

Declare the Air's `HostName` and `User` once in `modules/home/ssh.nix`. Derive both `air` and `air-batch` from that shared identity. The batch alias adds its transport policy while the interactive alias continues to inherit the global policy.

A separate alias makes intent visible at every call site and avoids weakening multiplexing for Git and interactive sessions. Overriding `air` globally would be simpler, but it would discard the reason the global policy exists. Repeating five SSH options at every invocation is correct but obscures the boundary and invites omissions.

### Encode a batch transport, not a command wrapper

The batch alias declares:

- `BatchMode yes`
- `RequestTTY no`
- `ControlMaster no`
- `ControlPath none`
- `ControlPersist no`
- a bounded connection-establishment timeout

Do not set `StdinNull yes` on the host alias. `rsync` and similar clients carry their protocol through SSH standard streams. Direct command-only callers use SSH's standard `-n` option when they do not supply remote stdin. This separates caller input ownership from connection persistence.

The three control settings are deliberate. They override the global defaults explicitly, prevent use of an existing control socket, and prevent a new process from persisting after the command.

### Keep remote executable paths at deployment interfaces

Do not add Docker Desktop paths to remote shell startup files. Configure Teralizer's existing `CORPUS_EXPORT_DOCKER` boundary with the verified absolute Docker executable on the Air and configure `CORPUS_EXPORT_HOST=air-batch`. Other automation follows the same rule when its remote tool is absent from the non-interactive `PATH`.

This keeps host-specific installation facts out of the SSH transport. Teaching the remote shell to find Docker would affect unrelated sessions and would still leave automation dependent on shell startup semantics.

### Verify the rendered configuration without contacting the Air

Add a flake check over the evaluated Home Manager SSH settings and rendered configuration. It verifies that both aliases share identity, that only `air-batch` overrides the control and prompt policy, that standard input remains available, and that the interactive alias still inherits the global multiplexing policy.

A source-text check would be brittle. Evaluation checks the declaration that Home Manager will render. The check must not open a network connection so CI and offline evaluation remain deterministic.

### Provide one bounded live acceptance command

Package a small `air-batch-check` command for operator-run verification. It uses explicit per-step deadlines and exercises:

1. a command-only success with stdin detached,
1. propagation of an expected remote nonzero exit,
1. a read-only `rsync` transfer to a temporary local directory,
1. read-only Docker inspection through the configured absolute remote executable, and
1. absence of a persistent control socket or SSH master created by the batch alias.

The command reports the failed boundary and removes only its local temporary directory. It does not mutate the Air or Docker state. The README documents when to run it and how to configure the host-specific Docker path.

Connection timeout settings alone are not a workload timeout, so they cannot replace the acceptance command's per-step deadlines.

## Risks / Trade-offs

- \[The `air` and `air-batch` identities drift\] → Build both aliases from one Nix value and assert equality in the configuration check.
- \[A host-level stdin null setting breaks `rsync`\] → Preserve standard streams on the alias and detach stdin only in command-only invocations.
- [A remote Docker installation moves] → Keep the path in the existing deployment-specific configuration and fail the live check with the unresolved path.
- [An SSH command itself legitimately exceeds the acceptance deadline] → Apply deadlines only to fixed probes, not to arbitrary corpus exports or remote workloads.
- [The temporary Air outlives its intended scope in configuration] → Link removal of `air-batch` to the same return task that removes `air`; do not reference it from fleet configuration.

## Migration Plan

1. Add the shared Air identity, the `air-batch` alias, the static check, the acceptance command, and concise README guidance.
1. Run formatting, the focused SSH configuration checks, the full flake checks, and the Darwin build-plan inspection without contacting the Air.
1. Activate the generation and verify that `ssh air` retains its current resolved policy.
1. Run `air-batch-check` against the reachable Air with the reviewed Docker executable path.
1. Configure Teralizer corpus export to use `air-batch` and the same Docker path, then run its positive control separately under the Teralizer change.
1. Roll back by activating the prior Nix generation if the SSH policy or acceptance command is wrong. This does not change remote state.
1. Remove `air-batch`, its acceptance surface, and `air` together when the Air return procedure reaches host decommissioning.
