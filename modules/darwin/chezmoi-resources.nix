{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.chezmoi.resources = lib.mkOption {
    type = lib.types.attrsOf lib.types.anything;
    default = { };
    internal = true;
    description = "Role-owned immutable inputs for chezmoi user configuration.";
  };
  config.environment.etc."chezmoi-resources/manifest.json".source =
    (pkgs.formats.json { }).generate "chezmoi-resources-manifest.json"
      config.chezmoi.resources;
}
