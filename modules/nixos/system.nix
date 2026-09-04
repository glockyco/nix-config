{
  config,
  inputs,
  pkgs,
  ...
}:

let
  inherit (config.host) name username;
in
{
  networking.hostName = name;

  # Matches the pinned nixpkgs release; changing it changes option defaults.
  system.stateVersion = "26.05";

  # Expose the active commit in `nixos-version`, as `modules/darwin/system.nix`
  # does for `darwin-version`. This value enters the system derivation, so the
  # system path moves with every commit. A closure diff is therefore the way to
  # compare two generations; a store-path comparison reports every commit as a
  # change.
  system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;

  # macOS supplies the time zone and the number formats, so no portable module
  # declares them. Without these values the host runs on UTC and reports
  # 12-hour time and US measurement, which `en_US.UTF-8` selects.
  time.timeZone = "Europe/Vienna";

  # `de_AT.UTF-8` reports `%T` for the time format and `1` for measurement,
  # which is 24-hour and metric. Declaring the categories is enough, because
  # the built locale set derives from them; `i18n.supportedLocales` is
  # deprecated and stays unset.
  i18n.extraLocaleSettings = {
    LC_TIME = "de_AT.UTF-8";
    LC_MEASUREMENT = "de_AT.UTF-8";
  };

  # `nixos-wsl` already declares this account, including `isNormalUser` and the
  # `wheel` group that `sudo` needs. Only the values it leaves open belong here.
  users.users.${username} = {
    home = "/home/${username}";

    # `modules/home/shell.nix` configures zsh and generates no bash files, so a
    # bash login shell would read none of its own configuration.
    shell = pkgs.zsh;
  };
}
