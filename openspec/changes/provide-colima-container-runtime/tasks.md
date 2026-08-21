## 1. Declare the container client boundary

- [x] 1.1 Add `modules/home/container-runtime.nix` with `pkgs.colima` and the client-only `pkgs.docker-client`, then import it from `modules/home/default.nix`.
- [x] 1.2 Set `COLIMA_HOME` to the XDG Colima directory and manage the default profile configuration through Home Manager.
- [x] 1.3 Declare the complete profile values for Docker, `aarch64`, `vz`, Rosetta, `virtiofs`, disabled Kubernetes, shared nonreachable networking, disabled SSH agent forwarding, 8 CPUs, 16 GiB memory, and a 150 GiB sparse disk limit.
- [x] 1.4 Add evaluation checks that reject an unimported module, missing client packages, automatic startup configuration, a global Docker socket link, or omitted profile fields.
- [x] 1.5 Prove from the built Home Manager generation that `docker compose` resolves the Nixpkgs-packaged plugin without any plugin under mutable Docker configuration.

## 2. Build bounded runtime acceptance

- [x] 2.1 Add a Nix-packaged `container-runtime-check` command and expose it in the workstation profile and flake package outputs.
- [x] 2.2 Pin digest-addressed multi-architecture smoke and PostgreSQL images, record their expected architectures, and reject mutable image references in evaluation checks.
- [x] 2.3 Implement acceptance preflight that requires the Colima context, confirms the expected Linux engine identity, and fails with a corrective command when the runtime is stopped or redirected.
- [x] 2.4 Add bounded ARM64 and AMD64 smoke execution and verify the architecture reported by each container.
- [x] 2.5 Add a generated Compose fixture with a health-checked PostgreSQL service, a unique explicit project name, a dynamically selected loopback port, a named volume, and a bind-mounted temporary directory.
- [x] 2.6 Verify service health, named-volume persistence across restart, `docker compose exec`, `docker compose cp`, and `docker compose run --rm` against the fixture.
- [x] 2.7 Add an unrelated sentinel Compose project, remove the acceptance project and its volume, and prove the sentinel resources remain unchanged.
- [x] 2.8 Add fixed timeouts, an interruption-safe cleanup trap, retained diagnostic logs, and a printed recovery command for every acceptance failure.
- [x] 2.9 Test the acceptance command's preflight, timeout, diagnostic, and cleanup branches with controlled command doubles without requiring a running VM in `nix flake check`.

## 3. Document operation and recovery

- [x] 3.1 Add `docs/operations/container-runtime.md` with first start, readiness, status, routine shutdown, storage inspection, and the real acceptance command.
- [x] 3.2 Document that profile configuration changes happen through Nix, normal operation must not use `colima start --edit`, and activation never starts or deletes the VM.
- [x] 3.3 Document upgrade preparation, failed-start diagnosis, explicit profile recreation, data-loss boundaries, and rollback to the previous Nix generation.
- [x] 3.4 State that Rosetta results prove workstation compatibility but do not replace native Linux x86-64 release validation.
- [x] 3.5 Link the operations guide from `README.md` and list the container runtime check beside the existing release gates.

## 4. Verify the inactive generation

- [x] 4.1 Confirm no Colima profile, Docker context, Docker configuration directory, or global Docker socket exists before activation, and record this clean baseline.
- [x] 4.2 Run `nix fmt -- --fail-on-change` and correct every formatting change before continuing.
- [x] 4.3 Run `nix flake check --print-build-logs` and prove all static and controlled acceptance tests pass without a container runtime.
- [x] 4.4 Run `nix run .#check-darwin-build-plans` and confirm the new closure does not introduce an uncached source-built dependency.
- [x] 4.5 Run `nix build .#darwinConfigurations.macbook-pro.system` and inspect the resulting generation for the declared clients, profile, and acceptance command.
- [x] 4.6 Run the commit hooks and strict OpenSpec validation, then require a clean worktree before review.

## 5. Activate and exercise the real boundary

- [x] 5.1 After review and merge, activate the generation with `darwin-switch`, inspect activation output, and prove activation created no Colima VM and started no container service.
- [x] 5.2 Start the default profile, verify the active context and declared resources, and run `container-runtime-check` to completion on the actual Apple Silicon host.
- [x] 5.3 Stop the profile and prove Docker workload commands fail against the stopped Colima endpoint rather than selecting another endpoint.
- [x] 5.4 Restart the profile, run the Teralizer `jarvis-scenarios` export and isolated Compose restore positive control, then stop and remove only the positive-control resources.
- [x] 5.5 Confirm a same-generation activation preserves images and volumes, then retain the previous Nix generation until the downstream Teralizer verification completes.
- [x] 5.6 Record the measured runtime, peak memory, disk allocation, engine architecture, image digests, and acceptance outcome in the operations evidence section.
