## Context

Korolev runs rootless Podman 5.8.6 with `dockerCompat`, so `docker` is Podman. `podman compose` delegates to an external provider, and none is installed. The NixOS Podman module already enables the socket-activated user socket `/run/user/1000/podman/podman.sock`, in a mode-0700 runtime directory, and the system socket `/run/podman/podman.sock`, owned by `root:podman` with an empty `podman` group. `dockerSocket.enable = false` only keeps `/run/docker.sock` absent; the declaration's comment says the host has no socket, which is wrong.

A probe with the pinned providers, selected through `PODMAN_COMPOSE_PROVIDER`, gave:

- `docker-compose` 5.4.0: `docker compose run --rm` started a `service_completed_successfully` dependency first, refused the job with exit 1 when that dependency failed, returned at once with `run -d`, and wrote bind-mounted files as the user.
- `podman-compose` 1.5.0: ran the job and exited 0 although the dependency failed, and names containers with underscores, so mixing the providers left orphaned containers.

The Mac uses the same official Compose, and SCCH's goldberg runs Docker Compose 5.1.4.

## Goals / Non-Goals

**Goals:**

- `docker compose` on Korolev with the semantics of the Mac and of Docker hosts.
- No new endpoint and no change to the rootless model.

**Non-Goals:**

- A Docker engine, Docker Desktop integration, or a `/run/docker.sock` link.
- A real Docker CLI with contexts, as on the Mac; Podman's `docker` command stays.
- Making the Mac's Colima acceptance package cross-platform.

## Decisions

### 1. Official Compose as the only provider

Set `virtualisation.containers.containersConf.settings.engine.compose_providers` to the Nix store path of `pkgs.docker-compose`. Podman then runs it with `DOCKER_HOST` set to the user's socket. An explicit path avoids a `PATH` search that could pick up `podman-compose` or a user-installed binary. `podman-compose` was rejected for ignoring a failed dependency.

### 2. No banner

Set `compose_warning_logs = false`. Otherwise every Compose command prints a provider notice to stderr.

### 3. Existing sockets are the endpoint

Compose uses the user socket the Podman module already provides. Correct the declaration's comment to say what `dockerSocket.enable = false` prevents and why the existing local sockets keep the boundary in the `container-runtime` and `wsl-host` specs.

### 4. Static check and bounded live procedure

Extend the `container-runtime` evaluation check to assert the provider list and the disabled banner. Document a live procedure in `docs/operations/container-runtime.md`: `docker compose version`, then a two-service project in a temporary directory with a failing dependency, a passing dependency and a bind-mount ownership check, followed by `docker compose down` and removal of the directory. A package like the Mac's acceptance check is not needed for three commands.

## Risks / Trade-offs

- [Podman's Docker API differs from Docker's in places] → Project files are tested on both; the probe covered dependency conditions, detached runs, host networking and bind mounts.
- [Rootless user mapping differs from rootful Docker: container root is the WSL user here but real root on a Docker host] → Projects that write into bind mounts must handle ownership themselves; the spec fixes Korolev's behavior.
- [The user socket starts the API service on demand] → It already does for any API client; Compose adds no new trigger beyond the user's own commands.

## Migration Plan

Activate under the README release procedure and keep the previous generation. Rolling back removes the provider setting; containers, images and volumes remain.
