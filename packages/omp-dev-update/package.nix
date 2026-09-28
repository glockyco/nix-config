{
  cacert,
  coreutils,
  gh,
  git,
  lib,
  nix,
  personal-omp-plugin,
  python3Packages,
  stdenv,
  writeText,
}:

let
  config = writeText "omp-dev-update.json" (
    builtins.toJSON {
      upstreamUrl = "https://github.com/can1357/oh-my-pi.git";
      githubRepo = "can1357/oh-my-pi";
      patchUrl = "https://github.com/glockyco/oh-my-pi.git";
      patchBase = "2e07c170b514df32f45b3e84cb8660c3ed86a93d";
      patchTip = "61ab25eb3e9fbe54b7981ab74e5ed012f6372058";
      system = stdenv.hostPlatform.system;
      plugin = toString personal-omp-plugin;
      git = lib.getExe git;
      gh = lib.getExe gh;
      nix =
        if stdenv.hostPlatform.isDarwin then "/nix/var/nix/profiles/default/bin/nix" else "${nix}/bin/nix";
      nixStore =
        if stdenv.hostPlatform.isDarwin then
          "/nix/var/nix/profiles/default/bin/nix-store"
        else
          "${nix}/bin/nix-store";
      nixPackage = if stdenv.hostPlatform.isDarwin then "" else toString nix;
    }
  );
  profileFixture = writeText "omp-update-test-profile" "Test-only retained profile target.\n";
  certificate = "${cacert}/etc/ssl/certs/ca-bundle.crt";
  tools = [
    git
    gh
    coreutils
  ]
  ++ lib.optional stdenv.hostPlatform.isLinux nix;
in
python3Packages.buildPythonApplication (finalAttrs: {
  pname = "omp-dev-update";
  version = "0.1.0";
  pyproject = true;
  src = ./.;

  build-system = [ python3Packages.setuptools ];
  nativeCheckInputs = [
    python3Packages.unittestCheckHook
    git
  ];
  doCheck = true;

  preCheck = ''
    export OMP_DEV_UPDATE_TEST_PROFILE=${profileFixture}
    export OMP_DEV_UPDATE_TEST_COMMAND=$out/bin/omp-dev-update
    export OMP_DEV_UPDATE_TEST_CERTIFICATE=${certificate}
    export OMP_DEV_UPDATE_TEST_TOOLS=${lib.makeBinPath tools}
  '';

  makeWrapperArgs = [
    "--set"
    "SSL_CERT_FILE"
    certificate
    "--set"
    "NIX_SSL_CERT_FILE"
    certificate
    "--prefix"
    "PATH"
    ":"
    (lib.makeBinPath tools)
    "--add-flags"
    (lib.escapeShellArg "--config ${config}")
  ];

  passthru.tests = finalAttrs.finalPackage;

  meta = {
    description = "Prepare and select verified patched OMP source generations";
    mainProgram = "omp-dev-update";
    platforms = [
      "aarch64-darwin"
      "x86_64-linux"
    ];
  };
})
