# Container Runtime

Use this procedure for the Mac's first Colima start, runtime acceptance, or recovery.
First complete [activation](../../README.md#activate). Activation installs files but never starts or deletes the virtual machine.
The [profile declaration](../../modules/home/darwin/container-runtime.nix) owns configuration, not images, containers, volumes, credentials, logs, or disks.

## Start and verify

Check free storage before the first start:

```sh
df -h "$HOME"
colima start
colima status --extended
docker context show
docker info --format '{{.OSType}}/{{.Architecture}} {{.Name}}'
container-runtime-check
```

The disk limit in the declaration is sparse, not an immediate allocation.
The context must be `colima`. The engine must report Linux on ARM64 with the name `colima`.
Do not use `colima start --edit`. Change the declaration through review and activation instead.

The [acceptance command](../../packages/container-runtime-check.nix) uses fixed time limits and removes its two unique Compose projects.
It verifies Compose discovery, ARM64 and Rosetta AMD64 execution, PostgreSQL health, service operations, mounts, volumes, and project isolation.
On failure, use its printed cleanup commands and retained diagnostic directory.
Rosetta does not replace native Linux x86-64 release checks.

## Inspect and stop

Inspect storage and workloads before shutdown:

```sh
colima status --extended
colima list
docker system df
du -sh "$COLIMA_HOME"
docker ps
docker compose ls
colima stop
docker context show
docker info
```

The activated shell sets `COLIMA_SAVE_CONFIG=false` and `DOCKER_CONTEXT=colima`.
After shutdown, the context must still report `colima`, and `docker info` must fail.
Do not select another endpoint to hide a stopped profile.
If this procedure started Colima only for acceptance, leave it stopped afterward.

## Optional MacBook Air verification

For the separate `air-batch` endpoint, first confirm that the Air is reachable and authenticated, with its Docker engine running.
Use the reviewed absolute Docker executable path on the Air:

```sh
AIR_BATCH_DOCKER='/absolute/path/to/docker' air-batch-check
```

The [bounded verifier](../../packages/air-batch-check.nix) checks command completion, exit-status propagation, an rsync transfer, Docker inspection, and connection cleanup.
On failure, follow its printed recovery instructions. This optional endpoint is not the MacBook Pro's Nix builder.

## Upgrade or roll back

Stop Colima before an update that changes Colima, Lima, Docker, or Compose.
Follow [Update](../../README.md#update) and [Activate](../../README.md#activate), then repeat [Start and verify](#start-and-verify).
Keep the previous generation until acceptance and the [release gates](../../README.md#develop) pass.

For a Nix rollback, follow [Recover](../../README.md#recover).
Stop Colima first if the generations declare incompatible profile values.
Nix rollback restores immutable clients and the profile declaration, not Docker data.

## Failed start

Inspect the active profile and context:

```sh
colima status --extended
docker context show
```

If the context is wrong, start a new activated shell or restore the declared override:

```sh
export DOCKER_CONTEXT=colima
```

If the profile is stopped, collect verbose startup output:

```sh
colima start --verbose
```

After the engine becomes ready, run `container-runtime-check` again.
Use its retained logs for Docker or Compose failures.

## Profile recreation

**CAUTION: Export all required database and volume data before deletion.**
`colima delete --data` removes the virtual machine and its Docker data, but does not change Nix generations.
Confirm that the data is disposable before these commands:

```sh
colima stop
colima delete --data
colima list
colima start
container-runtime-check
```

A smaller disk requires this destructive recreation. An increased disk limit does not.
If this procedure started Colima only for acceptance, finish with `colima stop`.
