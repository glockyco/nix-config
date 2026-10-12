# Container runtime

The Mac runs Docker in Colima and Korolev runs Docker Desktop. Projects own their images, build commands and data.

## Mac

Nix installs Colima, Docker and Compose. Chezmoi writes the Colima profile from the [shared host facts](../../home/.chezmoidata/hosts.toml). Activation never starts or deletes the virtual machine. The shell sets `COLIMA_SAVE_CONFIG=false` and `DOCKER_CONTEXT=colima`, so a stopped profile fails instead of falling back to another Docker endpoint. Change the profile through the declaration, never with `colima start --edit`.

### Start and verify

```sh
df -h "$HOME"
colima start
container-runtime-check
```

The declared disk size is sparse, so check free space rather than reserve it. [container-runtime-check](../../packages/container-runtime-check/package.nix) verifies Compose, ARM64 and Rosetta AMD64 containers, a PostgreSQL service, mounts, volumes and project isolation, then removes its projects. On failure it prints cleanup commands and keeps a diagnostic directory.

### Inspect and stop

```sh
colima status --extended
docker system df
docker compose ls
colima stop
```

### Update or roll back

Stop Colima before an update that changes Colima, Lima, Docker or Compose. After activation, start and verify again. A Nix rollback does not restore the chezmoi-written profile or Docker data, so roll back user files as well, as described under [Recover](../../README.md#recover).

### Failed start

```sh
colima status --extended
docker context show
colima start --verbose
```

If the context is not `colima`, open a new shell or run `export DOCKER_CONTEXT=colima`.

### Recreate the profile

Recreating the profile deletes the virtual machine and all Docker data, including databases and volumes. Export what you need first. Shrinking the disk requires recreation, growing it does not.

```sh
colima stop
colima delete --data
colima start
container-runtime-check
```

## Korolev

The workstation engine installs Docker Desktop with the WSL 2 backend and without Windows containers. Its installer asks for Administrator credentials. Start Docker Desktop once and accept the subscription agreement. WSL 2 needs no `docker-users` membership, so the engine never changes local groups. Intune updates an existing installation, so the engine never pins or downgrades it.

Verify in a new PowerShell:

```powershell
docker context show
docker run --rm hello-world
docker compose version
```

The context must be `desktop-linux`. Mount project data from `S:\` or `\\scch.at\SCCH`.

## MacBook Air

The borrowed Air runs its own Docker engine. With the Air reachable, check the `air-batch` endpoint from the Mac with its absolute Docker path:

```sh
AIR_BATCH_DOCKER='/absolute/path/to/docker' air-batch-check
```
