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

      AppleShowAllExtensions = true;

      # Smart quotes and dashes corrupt code and shell commands.
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
    };

    finder = {
      AppleShowAllExtensions = true;
      FXPreferredViewStyle = "Nlsv";
      ShowPathbar = true;
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
    };
  };
}
