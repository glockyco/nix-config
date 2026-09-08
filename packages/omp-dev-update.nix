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
      patchBase = "daf07999c2fee9b22edc7bf8fea1fb6272e0df5e";
      patchTip = "16a6bd10e859ca26a0011ed5ba26d4c260e2b754";
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
