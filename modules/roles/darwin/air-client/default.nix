# The borrowed MacBook Air is temporary. Issue #17 retires it after the
# research results are preserved and its tailnet node is revoked. Its complete
# repository footprint includes this directory, `packages/air-batch-check/`,
# `packages/air-share-mount/`, `home/.chezmoidata/air.toml` and chezmoi Air files,
# `checks/air-batch-config-check.nix`, this role's import in
# `hosts/macbook-pro/default.nix`, the `hasAirClient` export condition in
# `flake-modules/packages.nix`, the two Air check branches in
# `flake-modules/checks.nix`, the `macbook-air` peer in
# `modules/shared/tailnet-peers.nix`, and the Air text in `README.md` and
# `docs/operations/container-runtime.md`. Delete all of them together.
{ ... }:
{
  host.importedRoles.airClient = true;
  imports = [
    ./ssh.nix
    ./network-shares.nix
  ];
}
