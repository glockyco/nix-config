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
  render =
    executable:
    if executable ? absolute then
      ''"${toString executable.absolute}"''
    else
      ''"$HOME/${executable.homeRelative}"'';

  absolute = evaluate {
    name = "absolute-host";
    username = "absolute-user";
    build.logicalCores = 12;
    tailnet.tag = "tag:absolute-host";
    ompRuntime = {
      executable.absolute = "/opt/homebrew/bin/omp";
      installCommand = "install absolute omp";
    };
  };

  homeRelative = evaluate {
    name = "relative-host";
    username = "relative-user";
    tailnet.tag = "tag:relative-host";
    ompRuntime = {
      executable.homeRelative = ".local/lib/oh-my-pi/omp";
      installCommand = "install relative omp";
    };
  };

  missingUsername = force {
    name = "missing-user";
    tailnet.tag = "tag:missing-user";
    ompRuntime = {
      executable.absolute = "/opt/homebrew/bin/omp";
      installCommand = "install omp";
    };
  };

  bareExecutable = force {
    name = "bare-executable";
    username = "user";
    tailnet.tag = "tag:bare-executable";
    ompRuntime = {
      executable = "/opt/homebrew/bin/omp";
      installCommand = "install omp";
    };
  };

  relativeAbsolute = force {
    name = "relative-absolute";
    username = "user";
    tailnet.tag = "tag:relative-absolute";
    ompRuntime = {
      executable.absolute = "relative/omp";
      installCommand = "install omp";
    };
  };

  missingTag = force {
    name = "missing-tag";
    username = "user";
    ompRuntime = {
      executable.absolute = "/opt/homebrew/bin/omp";
      installCommand = "install omp";
    };
  };

  malformedTag = force {
    name = "malformed-tag";
    username = "user";
    tailnet.tag = "malformed-tag";
    ompRuntime = {
      executable.absolute = "/opt/homebrew/bin/omp";
      installCommand = "install omp";
    };
  };
in
assert
  absolute == {
    name = "absolute-host";
    username = "absolute-user";
    build.logicalCores = 12;
    tailnet = {
      tag = "tag:absolute-host";
      reachable = true;
    };
    ompRuntime = {
      executable.absolute = "/opt/homebrew/bin/omp";
      installCommand = "install absolute omp";
    };
  };
assert
  homeRelative == {
    name = "relative-host";
    username = "relative-user";
    build.logicalCores = null;
    tailnet = {
      tag = "tag:relative-host";
      reachable = true;
    };
    ompRuntime = {
      executable.homeRelative = ".local/lib/oh-my-pi/omp";
      installCommand = "install relative omp";
    };
  };
assert render absolute.ompRuntime.executable == ''"/opt/homebrew/bin/omp"'';
assert render homeRelative.ompRuntime.executable == ''"$HOME/.local/lib/oh-my-pi/omp"'';
assert !missingUsername.success;
assert !bareExecutable.success;
assert !relativeAbsolute.success;
assert !missingTag.success;
assert !malformedTag.success;
runCommand "check-host-declaration" { } "touch $out"
