{
  lib,
  runCommand,
  python3,
  chezmoi,
  git,
  zsh,
  host,
  resources,
  userPackages,
}:
let
  userPath = builtins.concatStringsSep ":" (map (package: "${package}/bin") userPackages);
in
runCommand "check-${host.name}-chezmoi"
  {
    nativeBuildInputs = [
      python3
      chezmoi
      git
      zsh
    ];
    inherit userPath;
    hostName = host.name;
    targetOS = if host.kind == "darwin" then "darwin" else "linux";
    resourceManifest = builtins.toJSON resources;
    source = lib.cleanSource ../.;
  }
  ''
    ${python3}/bin/python ${./chezmoi-render-check.py}
  ''
