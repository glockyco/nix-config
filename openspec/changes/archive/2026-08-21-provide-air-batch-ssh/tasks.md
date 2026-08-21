## 1. Declare the batch endpoint

- [x] 1.1 Refactor `modules/home/ssh.nix` so `air` and `air-batch` derive their host name and account from one Nix value without changing the rendered `air` policy.
- [x] 1.2 Declare `air-batch` with batch authentication, no terminal, no control socket, no persistent master, and a bounded connection timeout; leave SSH standard input available for protocol clients.
- [x] 1.3 Add a daemon-free flake check that verifies shared Air identity, every batch override, standard-stream availability, and unchanged interactive multiplexing in the evaluated Home Manager configuration.

## 2. Add bounded live acceptance

- [x] 2.1 Package an `air-batch-check` command with explicit per-step deadlines, a required reviewed remote Docker executable, isolated local temporary state, and failure-specific diagnostics.
- [x] 2.2 Make the command verify detached-stdin success, exact remote failure propagation, a read-only `rsync` transfer, read-only Docker inspection, and absence of a batch-created persistent master or control socket.
- [x] 2.3 Add controlled command-double tests for successful acceptance, timeout, authentication failure, remote command failure, transfer failure, missing Docker executable, and cleanup after failure without opening an SSH connection.
- [x] 2.4 Install the acceptance command in the workstation Home Manager package set and expose its package and tests through focused flake outputs.

## 3. Document the boundary

- [x] 3.1 Add concise README guidance that distinguishes `air` from `air-batch`, explains when command callers use `-n`, and requires explicit remote tool paths for non-interactive automation.
- [x] 3.2 Document the acceptance command, its required Docker path input, recovery diagnostics, and the rule that it performs no remote mutation.
- [x] 3.3 Update the Air return guidance so `air-batch`, its acceptance surface, and `air` are removed together without adding the Air to fleet configuration.

## 4. Run offline verification

- [x] 4.1 Run `nix fmt -- --fail-on-change` and correct every formatting change before continuing.
- [x] 4.2 Build the focused SSH configuration, acceptance-command, and controlled acceptance-test checks without network access to the Air.
- [x] 4.3 Run `nix flake check --print-build-logs` and confirm no flake check opens an SSH connection.
- [x] 4.4 Run `nix run .#check-darwin-build-plans` and inspect the Darwin system build plan for unintended source-built dependencies.
- [x] 4.5 Run the repository hooks and strict OpenSpec validation, then require a clean reviewed worktree before live activation.

## 5. Verify the activated behavior

- [x] 5.1 Record the pre-activation resolved `air` policy and confirm no `air-batch` host or related control socket exists.
- [x] 5.2 Activate the new Darwin generation and prove the resolved `air` policy is unchanged while `air-batch` resolves the declared batch options and shared identity.
- [x] 5.3 Run `air-batch-check` against the reachable Air with its verified absolute Docker executable and record the elapsed time and outcome of every fixed probe.
- [x] 5.4 Confirm the acceptance run leaves no remote files, Docker mutations, persistent SSH master, control socket, or local temporary directory.
- [x] 5.5 Configure the subsequent Teralizer corpus-export positive control with `CORPUS_EXPORT_HOST=air-batch` and the verified `CORPUS_EXPORT_DOCKER` path; leave execution and evidence ownership in the Teralizer change.

## 6. Preserve rollback and removal

- [x] 6.1 Confirm activating the previous Nix generation restores the prior SSH configuration without changing the Air, then reactivate the verified generation.
- [x] 6.2 Record the exact files and flake outputs that must be deleted with both Air aliases during the existing equipment-return procedure.
