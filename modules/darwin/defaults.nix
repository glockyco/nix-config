{ config, ... }:

{
  # Declarative macOS preferences. These are applied to `system.primaryUser`.
  #
  # Deliberately absent: `system.keyboard.remapCapsLockToControl`. Caps Lock is
  # the left Mod3 key in Neo2 and must reach Karabiner unmodified.
  system.defaults = {
    NSGlobalDomain = {
      # Hold-to-repeat instead of the accent picker. Required for a usable Neo2
      # layer 4 (held navigation keys) and for repeat to work at all.
      ApplePressAndHoldEnabled = false;

      # Both are counted in 15 ms ticks: 225 ms until repeat, 30 ms between.
      InitialKeyRepeat = 15;
      KeyRepeat = 2;

      # F1-F12 send real function keys; brightness, volume and the rest move
      # behind `fn`. This is the inverse of the macOS default.
      "com.apple.keyboard.fnState" = true;

      AppleShowAllExtensions = true;

      # Smart quotes and dashes corrupt code and shell commands; the rest of
      # the "helpful" text substitutions mangle identifiers and commit messages.
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;

      # Hold ctrl+cmd and drag anywhere in a window to move it, instead of
      # having to find the title bar.
      NSWindowShouldDragOnGesture = true;

      # Locale: German/Austrian conventions rather than the US defaults.
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

      # Stop asking for confirmation every time a file extension changes.
      FXEnableExtensionChangeWarning = false;

      # Search the folder you are actually looking at. "SCcf" is current
      # folder; the macOS default "SCev" searches the entire Mac, which is
      # almost never what you meant.
      FXDefaultSearchScope = "SCcf";

      # Allow cmd-Q to quit Finder.
      QuitMenuItem = true;
    };

    trackpad = {
      # Tap to click, off by default on every Mac.
      Clicking = true;
      TrackpadThreeFingerDrag = true;
    };

    dock = {
      autohide = true;
      show-recents = false;

      # Without these, autohide is unpleasant: macOS waits ~0.5 s before the
      # Dock even starts to appear, then plays a slow slide animation.
      # `autohide-delay` removes the wait entirely; `autohide-time-modifier`
      # scales the animation (1.0 is the default, 0.15 is quick but still
      # animated rather than a jarring snap).
      autohide-delay = 0.0;
      autohide-time-modifier = 0.15;

      # Stop Spaces from reordering themselves by recent use, which makes
      # "switch two desktops left" mean something different every time.
      mru-spaces = false;
    };

    WindowManager = {
      # Since Sonoma, clicking any empty patch of desktop hides every window.
      # This turns that off.
      EnableStandardClickToShowDesktop = false;
    };

    screencapture = {
      # Keep screenshots out of the Desktop. The directory is created by
      # modules/home/screenshots.nix -- macOS silently falls back to the
      # Desktop if the configured location does not exist.
      location = "${config.system.primaryUserHome}/Pictures/Screenshots";
      type = "png";
      disable-shadow = true;
    };
  };
}
