{
  config,
  pkgs,
  ...
}:

let
  containerRuntimeCheck = pkgs.callPackage ../../packages/container-runtime-check.nix { };
  profileFormat = pkgs.formats.yaml { };
  profile = {
    cpu = 8;
    disk = 150;
    memory = 16;
    arch = "aarch64";
    runtime = "docker";
    vmType = "vz";
    rosetta = true;
    mountType = "virtiofs";
    mounts = [
      {
        location = config.home.homeDirectory;
        writable = true;
      }
    ];
    kubernetes.enabled = false;
    autoActivate = true;
    network = {
      address = false;
      mode = "shared";
      hostAddresses = false;
    };
    forwardAgent = false;
  };
in

{
  home.packages = [
    pkgs.colima
    pkgs.docker-client
    containerRuntimeCheck
  ];

  home.sessionVariables = {
    COLIMA_HOME = "${config.xdg.configHome}/colima";
    COLIMA_SAVE_CONFIG = "false";
    DOCKER_CONTEXT = "colima";
  };

  xdg.configFile."colima/default/colima.yaml".source =
    profileFormat.generate "colima-default-profile.yaml" profile;
}
