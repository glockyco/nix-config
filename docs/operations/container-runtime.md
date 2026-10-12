# Container Runtime

Use this procedure for the Mac's first Colima start, runtime acceptance, or recovery.
First complete [system switch and user apply](../../README.md#initialize-and-apply-user-files). Nix installs the clients/resources; chezmoi writes the profile/environment. Neither step starts or deletes the virtual machine.
The desktop activation probes x86_64 execution before installing Rosetta. A failed Rosetta installation stops activation. Resolve that failure before the AMD64 container acceptance check; activation still does not start Colima.
The chezmoi profile owns only reviewed configuration, not images, containers, volumes, credentials, logs or disks. [Shared host facts](../../home/.chezmoidata/hosts.toml) own capacity and mounts; the Nix [container role](../../modules/roles/darwin/container-client/container-runtime.nix) derives architecture into `/etc/chezmoi-resources/manifest.json`. Runtime state remains application-owned.

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
Do not use `colima start --edit`. Change the shared declaration through review, system switch and ordinary-user chezmoi apply instead.

The [acceptance command](../../packages/container-runtime-check/package.nix) uses fixed time limits and removes its two unique Compose projects.
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

The [bounded verifier](../../packages/air-batch-check/package.nix) checks command completion, exit-status propagation, an rsync transfer, Docker inspection, and connection cleanup.
On failure, follow its printed recovery instructions. This optional endpoint is not the MacBook Pro's Nix builder.

## Upgrade or roll back

Stop Colima before an update that changes Colima, Lima, Docker, or Compose.
Follow [Update](../../README.md#update) and [Activate](../../README.md#activate), then repeat [Start and verify](#start-and-verify).
Keep the previous generation until acceptance and the [release gates](../../README.md#develop) pass.

For a Nix rollback, follow [Recover](../../README.md#recover).
Stop Colima first if the generations declare incompatible profile values.
Nix rollback restores immutable clients/resources, not the chezmoi-written profile or Docker data. Select the compatible previous chezmoi source revision and apply/verify it separately as the user.

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

## Korolev

Korolev uses native Docker Desktop and its bundled Docker CLI and Compose. Intune updates an existing installation but does not install it, so the engine installs it when missing and never pins or downgrades it.

The engine installs Docker Desktop with the WSL 2 backend and without Windows containers, as declared in `windows/workstation.json`. Its installer asks for Administrator credentials. Start Docker Desktop once and accept the subscription agreement yourself. WSL 2 needs no `docker-users` membership, so the engine never changes local groups.

In a fresh standard-user PowerShell, confirm the executable belongs to the native installation, inspect the context and engine, and run a disposable Compose workload. The helper bounds each Docker process to 120 seconds and reports output without falling back to WSL:

```powershell
$docker = (Get-Command docker.exe -CommandType Application).Source
if ($docker -notlike 'C:\Program Files\Docker\Docker\resources\bin\docker.exe') {
  throw "Unexpected Docker executable: $docker"
}
$smoke = Join-Path $env:TEMP ('docker-native-' + [guid]::NewGuid().ToString('N'))
$null = New-Item -ItemType Directory -Path $smoke
$project = 'native-' + [guid]::NewGuid().ToString('N')
function Invoke-SmokeDocker([string[]]$Arguments) {
  $stdout = Join-Path $smoke 'stdout.log'
  $stderr = Join-Path $smoke 'stderr.log'
  $process = Start-Process -FilePath $docker -ArgumentList $Arguments -PassThru `
    -RedirectStandardOutput $stdout -RedirectStandardError $stderr -NoNewWindow
  if (-not $process.WaitForExit(120000)) {
    $process.Kill()
    throw 'Docker smoke timed out after 120 seconds'
  }
  Get-Content $stdout, $stderr
  if ($process.ExitCode -ne 0) { throw "Docker exited $($process.ExitCode)" }
}
@'
services:
  job:
    image: docker.io/library/busybox:latest
    command: ["sh", "-c", "uname -m; touch /work/written"]
    volumes: ["./:/work"]
'@ | Set-Content -LiteralPath (Join-Path $smoke 'compose.yaml') -Encoding ascii
Push-Location $smoke
try {
  Invoke-SmokeDocker @('version')
  Invoke-SmokeDocker @('context', 'show')
  Invoke-SmokeDocker @('info', '--format', '{{.OSType}}/{{.Architecture}}')
  Invoke-SmokeDocker @('compose', 'version')
  Invoke-SmokeDocker @('compose', '-p', $project, 'up', '--abort-on-container-exit', '--exit-code-from', 'job')
  if (-not (Test-Path -LiteralPath 'written')) { throw 'Native bind mount failed' }
} finally {
  try { Invoke-SmokeDocker @('compose', '-p', $project, 'down', '--volumes', '--remove-orphans') }
  finally { Pop-Location }
}
Remove-Item -LiteralPath $smoke -Recurse
```

Require context `desktop-linux`, engine `linux/x86_64`, successful Compose and the bind-mount file. Record actual versions and output. On failure, retain the temporary diagnostic directory, inspect Docker Desktop and clean up only this unique Compose project. If verification alone started Docker Desktop, quit it after cleanup. Do not run `docker system prune`, delete volumes outside this project, or use a WSL-host fallback.

Projects own their container images, build commands and share roots. Use employer-managed `S:\` or `\\scch.at\SCCH` where required, not `/mnt/s`. The workstation does not own project toolchain images or migrate container databases automatically. Mac Colima remains unchanged.
