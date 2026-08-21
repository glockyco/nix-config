# Container Runtime

Colima provides the local Linux virtual machine and Docker Engine. Nix installs Colima, the Docker client, Compose, and the reviewed profile.

Nix does not own images, containers, volumes, credentials, logs, or the virtual machine disk. This state stays under `$COLIMA_HOME`.

## First start

Activate the workstation generation before the first start. Activation installs files only. It does not create, start, reset, or delete a Colima virtual machine.

Check the available host storage:

```sh
df -h "$HOME"
```

The profile has a 150 GiB sparse disk limit. The virtual machine does not allocate the complete limit at creation.

Start the default profile:

```sh
colima start
```

Do not use `colima start --edit`. Change `modules/home/container-runtime.nix`, build a new generation, and activate it instead.

The activated shell sets `COLIMA_SAVE_CONFIG=false` and `DOCKER_CONTEXT=colima`. Normal lifecycle commands can read the managed profile but cannot rewrite its Nix store target. Docker commands remain bound to the Colima endpoint.

Wait for Colima to report a running Docker runtime:

```sh
colima status --extended
docker context show
docker info --format '{{.OSType}}/{{.Architecture}} {{.Name}}'
```

The Docker context must be `colima`. The engine must report Linux on ARM64 with the name `colima`.

## Acceptance

Run the real workstation acceptance command:

```sh
container-runtime-check
```

The command verifies these boundaries:

- Nix-managed Compose discovery
- native ARM64 execution
- AMD64 execution through Rosetta
- PostgreSQL health and a dynamic loopback port
- image builds, bind mounts, named volumes, `exec`, `cp`, and `run --rm`
- cleanup isolation between two Compose projects

The command uses digest-addressed images and fixed time limits. It removes the two unique Compose projects that it creates.

A failure prints recovery commands. It also retains Docker and Compose logs in the reported temporary directory.

Rosetta results prove compatibility on this workstation. They do not replace release validation on native Linux x86-64.

## Routine status and shutdown

Inspect the profile and Docker storage:

```sh
colima status --extended
colima list
docker system df
du -sh "$COLIMA_HOME"
```

Inspect running workloads before shutdown:

```sh
docker ps
docker compose ls
```

Stop the default profile:

```sh
colima stop
```

Colima changes its stored active context to `default` during shutdown. The `DOCKER_CONTEXT=colima` environment override keeps workstation commands bound to the stopped Colima endpoint. A Docker workload must fail while the profile is stopped.

```sh
docker context show
docker info
```

`docker context show` must still report `colima`, and `docker info` must fail. Start the profile again with `colima start`. Do not select another endpoint to hide a stopped Colima profile.

## Upgrade preparation

Stop Colima before a Nixpkgs update that changes Colima, Lima, Docker, or Compose:

```sh
colima stop
nix flake update
nix fmt -- --fail-on-change
nix flake check --print-build-logs
nix run .#check-darwin-build-plans
nix build .#darwinConfigurations.macbook-pro.system
darwin-switch
colima start
container-runtime-check
```

Keep the previous Nix generation until the acceptance command and required repository checks pass.

A same-profile activation changes immutable clients and the managed profile file. It does not delete images, containers, volumes, or the virtual machine disk.

## Failed start

First, confirm the active configuration and context:

```sh
colima status --extended
docker context show
```

If the profile is stopped, start it with verbose output:

```sh
colima start --verbose
```

If `docker context show` does not report `colima`, start a new activated shell or restore the declared override:

```sh
export DOCKER_CONTEXT=colima
```

Run `container-runtime-check` again after the engine becomes ready. Use its retained diagnostic directory for Docker and Compose failures.

## Profile recreation

Profile recreation is destructive. Export all required database and volume data before this procedure.

Stop and remove the profile with its container data:

```sh
colima stop
colima delete --data
```

Confirm the deletion, then create the profile from the managed configuration:

```sh
colima list
colima start
container-runtime-check
```

`colima delete --data` removes the virtual machine and its Docker data. It does not remove or change Nix generations.

The 150 GiB disk limit can increase after profile creation. A smaller disk requires this destructive recreation procedure.

## Nix rollback

List the retained generations:

```sh
sudo darwin-rebuild --list-generations | cat
```

Restore the previous generation:

```sh
sudo darwin-rebuild --rollback
```

Or select a retained generation:

```sh
sudo darwin-rebuild --switch-generation <number>
```

Rollback restores immutable clients and the managed profile declaration. It does not restore or delete Docker state.

Stop Colima before rollback when the two generations declare incompatible profile values. Delete the profile only after its data is confirmed disposable.

## Evidence

### Clean pre-activation baseline

Recorded on 2026-08-21 before the first activation of this change:

- `~/.colima` was absent.
- `~/.config/colima` was absent.
- `~/.docker` was absent.
- `/var/run/docker.sock` was absent.

This baseline proves that the later activation and runtime steps start from no existing Colima profile, Docker context directory, mutable Docker configuration, or global socket.

### Activated runtime acceptance

Recorded on 2026-08-21 after activation:

- Colima reported 8 CPUs, 16 GiB of memory, and a 150 GiB sparse data disk.
- The Docker Engine reported Linux `aarch64`, version 29.2.1, and engine name `colima`.
- The sparse data disk had a logical size of 161,061,273,600 bytes and an allocated size of 1,549,176 KiB. The complete `$COLIMA_HOME` tree allocated 2,600,288 KiB.
- `container-runtime-check` passed in 21.63 seconds. `/usr/bin/time -lp` reported a maximum resident set size of 61,997,056 bytes.
- Acceptance used BusyBox digest `sha256:9db7b59979c38555a39def84a31fb98b5296952f9e3afd4f6f11f05b07adfab0` and PostgreSQL digest `sha256:00bc86618629af00d2937fdc5a5d63db3ff8450acf52f0636ec813c7f4902929`. Both resolved to `arm64` images.
- The Teralizer positive control used PostgreSQL 17.1 image digest `sha256:163763c8afd28cae69035ce84b12d8180179559c747c0701b3cad17818a0dbc5` on `arm64`.
- The `jarvis-scenarios` export checkpoint recorded 2 projects, 18,495,155 database bytes, a 380,308-byte dump, and SHA-256 `04bb388d432fa7e62af55fed20b39fa220ee8dfe3d17ea629ff563a82d5115e2`. The transferred dump matched that identity and checksum.
- The isolated restore, corpus preparation, project-count check, and report-role preflight passed. A Colima stop and start preserved the image digest, volume creation identity, restored database, and read-only preflight result.
