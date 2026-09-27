let
  username = "glockyco";
  home = "/Users/${username}";
  githubNoReplyEmail = "11704293+glockyco@users.noreply.github.com";
in
{
  host = {
    system = "aarch64-darwin";
    kind = "darwin";
    username = username;
    displayName = "MacBook Pro";
    timeZone = null;
    locale = {
      use24HourClock = true;
      useMetric = true;
    };
    paths = {
      configurationCheckout = "${home}/.config/nix-darwin";
      screenshots = "${home}/Pictures/Screenshots";
    };
    git = {
      authorName = "Johann Glock";
      defaultEmail = githubNoReplyEmail;
      githubNoReplyEmail = githubNoReplyEmail;
    };
    darwin = {
      applications = [
        {
          cask = "karabiner-elements";
          rationale = "The vendor package supplies the signed DriverKit extension.";
        }
        {
          cask = "ghostty";
          appPath = "/Applications/Ghostty.app";
          dockPosition = 5;
          rationale = "The terminal bundle matches the declared Neo2 rules.";
        }
        {
          cask = "fork";
          appPath = "/Applications/Fork.app";
          dockPosition = 9;
          rationale = "The proprietary Git client comes from its Homebrew cask.";
        }
        {
          cask = "zen";
          appPath = "/Applications/Zen.app";
          dockPosition = 6;
          rationale = "The browser follows vendor security updates.";
        }
        {
          cask = "brave-browser";
          rationale = "Brave hosts the Chrome-only browser relay.";
        }
        {
          cask = "thunderbird";
          rationale = "Mozilla supplies the signed binary and updater.";
        }
        {
          cask = "secretive";
          rationale = "The signed bundle supports Secure Enclave and Touch ID.";
        }
        {
          cask = "windows-app";
          rationale = "The signed client connects to the Windows desktop.";
        }
        {
          cask = "bitwarden";
          appPath = "/Applications/Bitwarden.app";
          dockPosition = 1;
          rationale = "The cask includes its Safari extension.";
        }
        {
          cask = "zed";
          appPath = "/Applications/Zed.app";
          dockPosition = 7;
          rationale = "The editor receives updates from its vendor.";
        }
        {
          cask = "discord";
          rationale = "Install the communication client.";
        }
        {
          cask = "ferdium";
          appPath = "/Applications/Ferdium.app";
          dockPosition = 2;
          rationale = "The app hosts communication services.";
        }
        {
          cask = "microsoft-teams";
          appPath = "/Applications/Microsoft Teams.app";
          dockPosition = 4;
          rationale = "The standalone app exposes the complete Teams settings.";
        }
        {
          cask = "signal";
          appPath = "/Applications/Signal.app";
          dockPosition = 3;
          rationale = "Signal has no web client for Ferdium.";
        }
        {
          cask = "ticktick";
          rationale = "Install the task client.";
        }
        {
          cask = "pdf-expert";
          appPath = "/Applications/PDF Expert.app";
          dockPosition = 8;
          rationale = "The vendor supplies the signed, self-updating bundle.";
        }
        {
          cask = "skim";
          rationale = "The PDF previewer supports SyncTeX.";
        }
        {
          cask = "rectangle-pro";
          rationale = "The window manager retains its Hookshot bundle ID.";
        }
        {
          cask = "crossover";
          rationale = "Install the Windows application compatibility layer.";
        }
        {
          cask = "unity-hub";
          rationale = "The vendor Hub owns editor installation and licensing.";
        }
        {
          cask = "launchbar";
          rationale = "Install the manually configured keyboard launcher.";
        }
      ];
      containerProfile = {
        cpu = 8;
        memory = 16;
        disk = 150;
        mounts = [
          {
            location = home;
            writable = true;
          }
        ];
      };
    };
    build.logicalCores = 15;
    tailnet.tag = "tag:macbook-pro";
  };
}
