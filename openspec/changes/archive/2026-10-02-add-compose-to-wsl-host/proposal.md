## Why

Project repositories describe their containers with Compose files: aqua's Langfuse stack, and next aqua's evaluation runs, which must behave the same on Korolev and on SCCH's Docker hosts. Korolev's `docker` command reaches rootless Podman, but `docker compose` fails with "looking up compose provider failed". The Mac already provides the official Compose plugin under the `container-runtime` capability.

## What Changes

- Configure the official Docker Compose from the pinned Nixpkgs input as Podman's only Compose provider on Korolev, so `docker compose` and `podman compose` run it against the user's rootless Podman API socket.
- Turn off Podman's banner for external Compose providers.
- Correct the declaration's claim that Korolev has no Podman socket: the NixOS Podman module already enables the socket-activated user socket and a root-only system socket. Neither is reachable from another host, and `/run/docker.sock` stays absent.
- Extend Korolev's evaluation check and document a bounded Compose acceptance procedure for Korolev.
- Do not add `podman-compose`, a Docker engine, or Docker Desktop integration.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `container-runtime`: The WSL host's runtime also serves Docker Compose through the official Compose implementation.

## Impact

`modules/roles/nixos/wsl-workstation/containers.nix`, the `container-runtime` check in `flake-modules/checks.nix`, and `docs/operations/container-runtime.md`. Activation writes `/etc/containers/containers.conf`; it starts no service and opens no network listener. Container images, volumes and the Podman sockets remain mutable or existing user state.
