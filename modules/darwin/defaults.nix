{ config, ... }:

{
  # Do not set `system.keyboard.remapCapsLockToControl`: Caps Lock is Neo2's
  # left Mod3 key and must reach Karabiner unchanged.

  system.defaults = {
    NSGlobalDomain = {
      # Disable the accent picker so held keys repeat for Neo2 layer 4.
      ApplePressAndHoldEnabled = false;

      # Repeat timings use 15 ms ticks: 225 ms delay, 30 ms interval.
      InitialKeyRepeat = 15;
      KeyRepeat = 2;

      # Enable F1-F12 function keys; media controls require `fn`.
      "com.apple.keyboard.fnState" = true;

      AppleShowAllExtensions = true;

      # Disable text substitutions and corrections to preserve code and identifiers.
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;

      # Explicitly disable this key: omitting it leaves a previous `true` value.
      # nix-darwin writes only specified keys.
      NSWindowShouldDragOnGesture = false;

      AppleICUForce24HourTime = true;
      AppleMetricUnits = 1;
      AppleMeasurementUnits = "Centimeters";
      AppleTemperatureUnit = "Celsius";
    };

    menuExtraClock.Show24Hour = true;

    finder = {
      AppleShowAllExtensions = true;
      FXPreferredViewStyle = "Nlsv";
      ShowPathbar = true;
      ShowStatusBar = true;

      AppleShowAllFiles = true;
      _FXSortFoldersFirst = true;

      FXEnableExtensionChangeWarning = false;

      # `SCcf` searches the current folder; `SCev` searches the entire Mac.
      FXDefaultSearchScope = "SCcf";

      QuitMenuItem = true;
    };

    trackpad = {
      Clicking = true;
      TrackpadThreeFingerDrag = false;
    };

    dock = {
      autohide = true;
      show-recents = false;

      # `autohide-delay` removes the wait; `autohide-time-modifier` shortens the animation.
      autohide-delay = 0.0;
      autohide-time-modifier = 0.15;

      # Disable MRU Space reordering so desktop-switch direction stays stable.
      mru-spaces = false;

      # Smaller than the 48 default, so a full Dock still fits comfortably.
      tilesize = 35;

      # These lists are authoritative: the Dock is rebuilt from them on every
      # switch, so rearranging it in the UI does not survive.
      #
      # Ordered left to right: credentials, chat, terminal, browser, editor,
      # version control, tasks. Brave is omitted because it exists only to
      # host the browser relay; background and menu-bar-only apps (Rectangle
      # Pro, Secretive) are absent for the same reason -- nothing here is
      # launched from the Dock.
      #
      # macOS appends running-but-unpinned apps after this list, so the
      # trailing spacer renders on that boundary. macOS offers no way to place
      # its thin divider there -- that one is fixed between the app region and
      # the files region -- so a narrow gap is as close as it gets.
      persistent-apps = [
        { app = "/Applications/Bitwarden.app"; }
        { app = "/Applications/Thunderbird.app"; }
        { app = "/Applications/Ferdium.app"; }
        { app = "/Applications/Discord.app"; }
        { app = "/Applications/Ghostty.app"; }
        { app = "/Applications/Zen.app"; }
        { app = "/Applications/Zed.app"; }
        { app = "/Applications/Fork.app"; }
        { app = "/Applications/TickTick.app"; }
        {
          spacer = {
            small = true;
          };
        }
      ];

      # Keep the right-hand side empty. An explicit list is required: omitting
      # the option would leave whatever the Dock already holds.
      persistent-others = [ ];
    };

    WindowManager = {
      # Prevent clicks on empty desktop space from hiding every window.
      EnableStandardClickToShowDesktop = false;

      # Rectangle Pro handles edge tiling; disable macOS edge-drag tiling to avoid
      # competing gesture handlers.
      EnableTilingByEdgeDrag = false;
      EnableTopTilingByEdgeDrag = false;
    };

    screencapture = {
      # macOS silently falls back to Desktop if the screenshot location is absent.
      location = "${config.system.primaryUserHome}/Pictures/Screenshots";
      type = "png";
      disable-shadow = true;
    };
  };
}
