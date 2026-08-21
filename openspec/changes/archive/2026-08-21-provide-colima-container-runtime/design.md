## Context

See `proposal.md` for motivation and `specs/container-runtime/spec.md` for the behavior contract.

The host is an Apple Silicon Mac with 48 GiB of memory and macOS 26. Project repositories already use Docker Compose as their executable container contract. The Teralizer workload also builds and runs `linux/amd64` Java images. macOS cannot run Linux containers without a virtual machine.

Nix owns executable paths and reviewed workstation configuration. Colima must own mutable virtual machine disks and Docker state. Workstation activation must remain bounded and must not depend on a running container service.

The pinned Nixpkgs Docker client is client-only on Darwin. Its default build includes Buildx and Compose, and its wrapper supplies their store paths through `DOCKER_CLI_PLUGIN_DIRS`. Installing a separate mutable Compose plugin is unnecessary.

## Goals / Non-Goals

**Goals:**

- Preserve the Docker CLI, Docker API, and Compose interface used by repositories.
- Keep all installed clients and profile defaults reproducible from the flake lock.
- Use Apple Virtualization.framework and Rosetta for efficient `linux/amd64` execution.
- Keep runtime creation and lifecycle under explicit user control.
- Provide one bounded acceptance command that cleans up its own Compose resources.
- Make runtime identity, resource allocation, mutable state, and recovery explicit.

**Non-Goals:**

- Do not install Docker Desktop, OrbStack, Podman Desktop, Rancher Desktop, or Apple `container`.
- Do not support Kubernetes or expose the container engine to the local network.
- Do not create `/var/run/docker.sock` or mount the Docker socket into workloads.
- Do not start Colima through activation or an always-running launch agent.
- Do not make Nix own images, containers, volumes, credentials, logs, or virtual machine disks.
- Do not claim that Rosetta validation replaces the release baseline on native Linux x86-64.

## Decisions

### Use Colima with its Docker runtime

Install `pkgs.colima` and `pkgs.docker-client` in a dedicated Home Manager module. Use Colima's Docker runtime rather than its containerd or Incus modes.

This keeps repository commands unchanged and uses an MIT-licensed runtime manager available from the pinned Nixpkgs cache. Direct Lima configuration would expose lower-level provisioning without adding useful control. Podman Machine would preserve OCI images but would place Compose and Docker API behavior behind a compatibility layer. Apple `container` does not provide the Compose contract this workstation needs. Docker Desktop and OrbStack provide strong compatibility, but both add application-managed installation and separate licensing boundaries.

### Use the Nixpkgs Docker client as the Compose integration

Rely on `pkgs.docker-client` with its existing Compose and Buildx support. Do not install a plugin under `~/.docker/cli-plugins` and do not construct a second wrapper.

Nixpkgs builds the client-only Darwin package with Compose support enabled. Its wrapper exports the plugin directory from the pinned store closure. A static flake check will assert that `docker compose version` reaches the packaged plugin without mutable Docker configuration.

### Manage one explicit Colima profile

Set `COLIMA_HOME` to the XDG configuration root for Colima and manage `default/colima.yaml` through Home Manager. Set `COLIMA_SAVE_CONFIG=false` so normal lifecycle commands do not rewrite the managed symlink. Normal operation uses `colima start`, `colima status`, `colima stop`, and `colima delete`. Users change the managed profile in Nix rather than using `colima start --edit`.

The profile declares these values:

- architecture `aarch64`
- runtime `docker`
- VM type `vz`
- Rosetta enabled
- mount type `virtiofs`
- the user's home mounted read-write for repository bind mounts
- Kubernetes disabled
- automatic Docker context activation enabled
- shared networking without a reachable VM address
- SSH agent forwarding disabled
- 8 virtual CPUs
- 16 GiB of memory
- 150 GiB sparse disk limit

The resource allocation leaves most of the 48 GiB host memory available to macOS while covering the repository's PostgreSQL and Java service limits. The sparse disk limit covers images, the restored evaluation databases, and temporary verification outputs without immediately consuming its maximum size.

A named default profile avoids wrapper-specific profile selection and matches Colima's standard Docker context. Set `DOCKER_CONTEXT=colima` for workstation sessions so Docker commands remain bound to that endpoint. Colima changes its stored active context to `default` during shutdown, but the environment override keeps commands on the stopped Colima socket instead of falling through to another endpoint.

### Separate declarative configuration from mutable state

Home Manager owns the client packages, `COLIMA_HOME`, and the profile configuration file. Colima owns all other files beneath its runtime home. Activation can update the managed configuration symlink but cannot create or start the VM.

Nix generation rollback restores the previous client and profile declaration. It does not roll back Docker data. Profile deletion remains an explicit destructive operator action.

### Split static checks from real runtime acceptance

Flake checks run without a container daemon. They will verify module import coverage, package availability, client-only Docker packaging, Compose plugin discovery, the complete profile declaration, and the absence of automatic startup or a global socket link.

A Nix-installed `container-runtime-check` command will exercise the actual macOS runtime after activation. It will:

1. Require the declared Colima context and report a stopped runtime clearly.
1. Run pinned digest-addressed ARM64 and AMD64 smoke images and verify their reported architectures.
1. Start a small pinned PostgreSQL Compose fixture under a unique project name and a dynamically selected loopback port.
1. Wait with a fixed timeout for service health.
1. Verify named-volume persistence, `exec`, `cp`, and `run --rm` behavior.
1. Confirm that cleanup removes only the unique acceptance project and its volume.
1. Stop only resources that the command started and retain diagnostic output on failure.

The command will not pull mutable tags. Image digests and expected architectures live in the Nix declaration or generated fixture so dependency updates remain reviewable.

### Document operator lifecycle next to workstation operations

Add one operations document for initial startup, routine status and shutdown, storage inspection, upgrades, failed-start recovery, profile recreation, and complete deletion. Link it from the root README and keep the release gate command in the document.

The document will state that Colima startup is intentional and stateful. It will also state that Nix activation and rollback do not restore Docker data.

## Risks / Trade-offs

- **A managed profile file may conflict with Colima commands that rewrite configuration.** → Set `COLIMA_SAVE_CONFIG=false`, use normal lifecycle commands in acceptance, prohibit `--edit` in the operator path, and change profile values only through Nix.
- **Rosetta behavior can differ from native Linux x86-64.** → Treat it as workstation compatibility evidence only and retain native Linux x86-64 as the artifact release baseline.
- **A runtime upgrade can require VM migration or recreation.** → Pin packages, review updates, stop the VM before risky upgrades, retain the previous Nix generation, and document profile recreation separately from rollback.
- **The 150 GiB disk limit cannot be reduced after profile creation.** → Document that it is a sparse maximum, verify available host space before first start, and require explicit deletion before any smaller replacement profile.
- **Container state is not covered by Nix rollback.** → Keep it outside activation by design, document volume backup where needed, and make destructive cleanup explicit.
- **Acceptance can leave resources after interruption.** → Use a unique project name, a cleanup trap, fixed timeouts, and a printed recovery command.
- **Docker context changes by other tools can redirect commands.** → Verify the active context and engine identity before every acceptance workload and fail on disagreement.

## Migration Plan

1. Add and import the Home Manager module, profile declaration, static checks, acceptance command, and operations document.
1. Run formatting, flake checks, build-plan inspection, and the full Darwin system build without activating the generation.
1. Review and merge the change according to the workstation release boundary.
1. Activate the merged generation with `darwin-switch` and inspect its output.
1. Confirm that activation did not create or start a Colima VM.
1. Start the declared profile and run the real `container-runtime-check` command.
1. Stop the profile after acceptance unless an active project needs it.

Rollback uses the previous Nix generation for clients and managed configuration. If the new profile has not been created, no runtime rollback is necessary. If it has been created, stop it before switching generations. Delete it only when its Docker data is confirmed disposable because generation rollback does not restore that data.
