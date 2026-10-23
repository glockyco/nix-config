{ config, lib, ... }:

let
  loginApplications = builtins.filter (
    application: application.startAtLogin
  ) config.host.darwin.applications;

  # Activation writes agent files by name without quoting, so the name keeps to safe characters.
  agentName =
    application:
    "open-"
    + lib.toLower (
      lib.strings.sanitizeDerivationName (lib.removeSuffix ".app" (baseNameOf application.appPath))
    );

  agentNames = map agentName loginApplications;
in
{
  # LaunchServices opens the bundle as an ordinary application, once per graphical login.
  launchd.user.agents = lib.listToAttrs (
    map (
      application:
      lib.nameValuePair (agentName application) {
        serviceConfig = {
          ProgramArguments = [
            "/usr/bin/open"
            "-a"
            application.appPath
          ];
          RunAtLoad = true;
          LimitLoadToSessionType = "Aqua";
        };
      }
    ) loginApplications
  );

  assertions = [
    {
      assertion = builtins.length agentNames == builtins.length (lib.unique agentNames);
      message = "host.darwin.applications starts two bundles with the same name at login";
    }
  ];
}
