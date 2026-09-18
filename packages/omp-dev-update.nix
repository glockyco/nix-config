{
  pkgs,
  lib,
  plugin,
}:

let
  config = pkgs.writeText "omp-dev-update.json" (
    builtins.toJSON {
      upstreamUrl = "https://github.com/can1357/oh-my-pi.git";
      githubRepo = "can1357/oh-my-pi";
      patchUrl = "https://github.com/glockyco/oh-my-pi.git";
      patchBase = "37273117021129e96bd05d8277b140ec3fd61990";
      patchTip = "6066a473e3cc682b19d82bb321e388a26677809d";
      system = pkgs.stdenv.hostPlatform.system;
      plugin = toString plugin;
      git = lib.getExe pkgs.git;
      gh = lib.getExe pkgs.gh;
      nix =
        if pkgs.stdenv.hostPlatform.isDarwin then
          "/nix/var/nix/profiles/default/bin/nix"
        else
          "${pkgs.nix}/bin/nix";
      nixStore =
        if pkgs.stdenv.hostPlatform.isDarwin then
          "/nix/var/nix/profiles/default/bin/nix-store"
        else
          "${pkgs.nix}/bin/nix-store";
      nixPackage = if pkgs.stdenv.hostPlatform.isDarwin then "" else toString pkgs.nix;
    }
  );
  updater = pkgs.writeShellApplication {
    name = "omp-dev-update";
    runtimeInputs = [
      pkgs.python3
      pkgs.git
      pkgs.gh
      pkgs.coreutils
    ]
    ++ lib.optional pkgs.stdenv.hostPlatform.isLinux pkgs.nix;
    text = ''
      export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      export NIX_SSL_CERT_FILE="$SSL_CERT_FILE"
      exec ${pkgs.python3}/bin/python3 ${./omp-dev-update.py} --config ${config} "$@"
    '';
  };
  profileFixture = pkgs.writeText "omp-update-test-profile" "Test-only retained profile target.\n";
  tests = pkgs.runCommand "check-personal-omp-update" { nativeBuildInputs = [ pkgs.git ]; } ''
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME"
    ${pkgs.python3}/bin/python3 ${./omp-dev-update-tests.py} ${./omp-dev-update.py} ${profileFixture}
    touch "$out"
  '';
in
updater.overrideAttrs (old: {
  passthru = (old.passthru or { }) // {
    inherit tests;
  };
})
