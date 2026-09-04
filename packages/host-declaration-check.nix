{
  lib,
  runCommand,
}:

let
  evaluate =
    host:
    (lib.evalModules {
      modules = [
        ../modules/fleet/host.nix
        { config.host = host; }
      ];
    }).config.host;

  force = host: builtins.tryEval (builtins.deepSeq (evaluate host) true);

  absolute = evaluate {
    name = "absolute-host";
    username = "absolute-user";
    ompRuntime = {
      executable.absolute = "/opt/homebrew/bin/omp";
      installCommand = "install absolute omp";
    };
  };

  homeRelative = evaluate {
    name = "relative-host";
    username = "relative-user";
    ompRuntime = {
      executable.homeRelative = ".local/lib/oh-my-pi/omp";
      installCommand = "install relative omp";
    };
  };

  missingUsername = force {
    name = "missing-user";
    ompRuntime = {
      executable.absolute = "/opt/homebrew/bin/omp";
      installCommand = "install omp";
    };
  };

  bareExecutable = force {
    name = "bare-executable";
    username = "user";
    ompRuntime = {
      executable = "/opt/homebrew/bin/omp";
      installCommand = "install omp";
    };
  };

  relativeAbsolute = force {
    name = "relative-absolute";
    username = "user";
    ompRuntime = {
      executable.absolute = "relative/omp";
      installCommand = "install omp";
    };
  };
in
assert
  absolute == {
    name = "absolute-host";
    username = "absolute-user";
    ompRuntime = {
      executable.absolute = "/opt/homebrew/bin/omp";
      installCommand = "install absolute omp";
    };
  };
assert
  homeRelative == {
    name = "relative-host";
    username = "relative-user";
    ompRuntime = {
      executable.homeRelative = ".local/lib/oh-my-pi/omp";
      installCommand = "install relative omp";
    };
  };
assert !missingUsername.success;
assert !bareExecutable.success;
assert !relativeAbsolute.success;
runCommand "check-host-declaration" { } "touch $out"
