{
  containerRuntimeCheck,
  coreutils,
  gnugrep,
  homeConfiguration,
  lib,
  runCommand,
}:

let
  profile = homeConfiguration.xdg.configFile."colima/default/colima.yaml".source;
  homeDirectory = homeConfiguration.home.homeDirectory;
  homePath = homeConfiguration.home.path;
  activationPackage = homeConfiguration.home.activationPackage;
  colimaAgents = builtins.filter (name: lib.hasInfix "colima" (lib.toLower name)) (
    builtins.attrNames homeConfiguration.launchd.agents
  );
  imageReferences = builtins.map (image: image.reference) (
    builtins.attrValues containerRuntimeCheck.images
  );
  immutableImages = builtins.all (
    reference: builtins.match ".+@sha256:[0-9a-f]{64}" reference != null
  ) imageReferences;
in

assert colimaAgents == [ ];
assert homeConfiguration.home.sessionVariables.COLIMA_SAVE_CONFIG == "false";
assert homeConfiguration.home.sessionVariables.DOCKER_CONTEXT == "colima";
assert immutableImages;
runCommand "check-container-runtime-configuration"
  {
    nativeBuildInputs = [
      coreutils
      gnugrep
    ];
  }
  ''
    test -x ${homePath}/bin/colima
    test -x ${homePath}/bin/docker
    test -x ${homePath}/bin/container-runtime-check
    test ! -e ${homePath}/bin/dockerd

    grep -qFx 'arch: aarch64' ${profile}
    grep -qFx 'autoActivate: true' ${profile}
    grep -qFx 'cpu: 8' ${profile}
    grep -qFx 'disk: 150' ${profile}
    grep -qFx 'forwardAgent: false' ${profile}
    grep -qFx '  enabled: false' ${profile}
    grep -qFx 'memory: 16' ${profile}
    grep -qFx 'mountType: virtiofs' ${profile}
    grep -qFx 'mounts:' ${profile}
    grep -qFx -- '- location: ${homeDirectory}' ${profile}
    grep -qFx '  writable: true' ${profile}
    grep -qFx '  address: false' ${profile}
    grep -qFx '  hostAddresses: false' ${profile}
    grep -qFx '  mode: shared' ${profile}
    grep -qFx 'rosetta: true' ${profile}
    grep -qFx 'runtime: docker' ${profile}
    grep -qFx 'vmType: vz' ${profile}

    ! grep -qF 'colima start' ${activationPackage}/activate
    ! grep -qF '/var/run/docker.sock' ${activationPackage}/activate

    export HOME=$TMPDIR/home
    export DOCKER_CONFIG=$TMPDIR/docker
    mkdir -p "$HOME" "$DOCKER_CONFIG"
    test ! -e "$DOCKER_CONFIG/cli-plugins"
    ${homePath}/bin/docker compose version > $TMPDIR/compose-version
    grep -qF 'Docker Compose version' $TMPDIR/compose-version

    touch $out
  ''
