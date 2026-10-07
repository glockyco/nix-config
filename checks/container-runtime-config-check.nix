{
  containerRuntimeCheck,
  coreutils,
  gnugrep,
  python3,
  buildEnv,
  hostConfig,
  renderedHome,
  host,
  platform,
  lib,
  runCommand,
  writeText,
}:
let
  userPackages = hostConfig.users.users.${host.username}.packages;
  userPath = buildEnv {
    name = "${host.name}-container-user-closure";
    paths = userPackages;
    pathsToLink = [
      "/bin"
      "/lib/docker/cli-plugins"
    ];
  };
  agents =
    hostConfig.launchd.user.agents // (hostConfig.launchd.agents or { }) // hostConfig.launchd.daemons;
  colimaAgents = builtins.filter (name: lib.hasInfix "colima" (lib.toLower name)) (
    builtins.attrNames agents
  );
  systemScripts = writeText "${host.name}-system-setup" (
    lib.concatMapStringsSep "\n" (script: script.text or "") (
      builtins.attrValues hostConfig.system.activationScripts
    )
    + "\n"
    + builtins.toJSON agents
  );
  imageReferences = map (image: image.reference) (builtins.attrValues containerRuntimeCheck.images);
  python = python3.withPackages (ps: [ ps.pyyaml ]);
in
assert host.roles.containerClient;
assert colimaAgents == [ ];
assert !lib.hasInfix "colima" (lib.toLower (builtins.toJSON agents));
assert builtins.all (
  reference: builtins.match ".+@sha256:[0-9a-f]{64}" reference != null
) imageReferences;
runCommand "check-${host.name}-container-runtime-configuration"
  {
    nativeBuildInputs = [
      coreutils
      gnugrep
      python
    ];
    profileFacts = builtins.toJSON host.darwin.containerProfile;
    expectedArch = platform.qemuArch;
    rendered = renderedHome;
    inherit systemScripts;
  }
  ''
    test -x ${userPath}/bin/colima
    test -x ${userPath}/bin/docker
    test -x ${userPath}/bin/container-runtime-check
    test ! -e ${userPath}/bin/dockerd
    python ${./chezmoi-container-check.py}

    export HOME=$TMPDIR/home
    export DOCKER_CONFIG=$TMPDIR/docker
    mkdir -p "$HOME" "$DOCKER_CONFIG"
    test ! -e "$DOCKER_CONFIG/cli-plugins"
    ${userPath}/bin/docker compose version > "$TMPDIR/compose-version"
    grep -qF 'Docker Compose version' "$TMPDIR/compose-version"
    test ! -e "$DOCKER_CONFIG/cli-plugins"
    touch "$out"
  ''
