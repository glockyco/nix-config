## 1. Declare Compose

- [x] 1.1 Set `compose_providers` to the pinned `docker-compose` and `compose_warning_logs = false` in `modules/roles/nixos/wsl-workstation/containers.nix`, and correct the socket comment; verify the rendered `/etc/containers/containers.conf` in the evaluated Korolev configuration.
- [x] 1.2 Extend the `container-runtime` check in `flake-modules/checks.nix` to assert the provider path and the disabled banner, and verify that it fails when either is removed.

## 2. Document

- [x] 2.1 Add a Korolev section with the bounded Compose procedure to `docs/operations/container-runtime.md`, and verify every command against the activated host.

## 3. Validate and activate

- [x] 3.1 Validate the OpenSpec change and run the repository's Nix formatting and flake gates.
- [x] 3.2 Review and commit the change; activate the committed Korolev configuration under the README release procedure, keeping the previous generation.
- [x] 3.3 On the activated host, run the documented procedure: `docker compose version` reports 5.4.0 without a banner, a failing dependency stops `docker compose run` with a nonzero status, and bind-mounted files belong to the user; verify that no `/run/docker.sock` exists.
