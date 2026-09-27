{
  containerRuntimeCheck,
  coreutils,
  gnugrep,
  homeConfiguration,
  host,
  platform,
  lib,
  runCommand,
}:

let
  profile = homeConfiguration.xdg.configFile."colima/default/colima.yaml".source;
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

    grep -qFx 'arch: ${platform.qemuArch}' ${profile}
    grep -qFx 'autoActivate: true' ${profile}
    grep -qFx 'cpu: ${toString host.darwin.containerProfile.cpu}' ${profile}
    grep -qFx 'disk: ${toString host.darwin.containerProfile.disk}' ${profile}
    grep -qFx 'forwardAgent: false' ${profile}
    grep -qFx '  enabled: false' ${profile}
    grep -qFx 'memory: ${toString host.darwin.containerProfile.memory}' ${profile}
    grep -qFx 'mountType: virtiofs' ${profile}
    grep -qFx 'mounts:' ${profile}
    ${lib.concatMapStringsSep "\n" (mount: ''
      grep -qFx -- '- location: ${mount.location}' ${profile}
      grep -qFx '  writable: ${if mount.writable then "true" else "false"}' ${profile}
    '') host.darwin.containerProfile.mounts}
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
