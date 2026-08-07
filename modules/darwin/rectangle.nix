{ lib, ... }:

let
  # Every Rectangle action whose keyboard shortcut is deliberately unbound. An
  # empty dictionary is how Rectangle records "no shortcut", as distinct from an
  # absent key, which means "use the default binding".
  #
  # Window management here is entirely cursor-driven -- Window Throw and
  # Move & Resize -- so the stock shortcuts are dead weight, and several of them
  # would sit on chords Neo2 and Karabiner already claim.
  #
  # This list is the set carried over from the previous machine rather than
  # every action Rectangle offers; actions absent from it keep their defaults.
  unboundShortcuts = [
    "almostMaximize"
    "appLeftHalf"
    "appRightHalf"
    "bottomCenterLeftEighth"
    "bottomCenterRightEighth"
    "bottomCenterSixth"
    "bottomLeftSixth"
    "bottomLeftThird"
    "bottomRightSixth"
    "bottomRightThird"
    "centerHalf"
    "centerTwoThirds"
    "fillBottomLeft"
    "fillBottomRight"
    "fillLeft"
    "fillTopLeft"
    "fillTopRight"
    "firstFourth"
    "firstSixth"
    "firstThreeFourths"
    "lastFourth"
    "lastThreeFourths"
    "middleRightNinth"
    "moveDown"
    "moveLeft"
    "nudgeRight"
    "nudgeUp"
    "prevSpace"
    "secondFourth"
    "snapTopLeft"
    "thirdFourth"
    "topCenterSixth"
    "topLeftEighth"
    "topLeftSixth"
    "topLeftThird"
    "topRightSixth"
    "topRightThird"
    "upperCenter"
  ];
in

{
  # Rectangle Pro, installed as a cask in modules/darwin/homebrew.nix. The domain
  # is `com.knollsoft.Hookshot`, from when the app was called Hookshot.
  #
  # What is deliberately NOT here: the `Paddle-*` licence keys and `fld`, which
  # are secret and this repository is public, and `displayCache`, which pins
  # monitor UUIDs and frames to one machine. All three are written by the app.
  #
  # Rectangle rewrites its own preferences when it quits, so a switch performed
  # while it is running is undone on the next quit. Restart it after a switch
  # that changes anything below.
  system.defaults.CustomUserPreferences."com.knollsoft.Hookshot" = {
    # The decisive one. A licence bought in the Hookshot era selects the Hookshot
    # default set, in which the cursor-movement features are bound out of the
    # box; a fresh Rectangle Pro install instead gets the keyboard-shortcut
    # oriented Rectangle defaults and leaves Move & Resize inert. Without this,
    # cursor movement does nothing on a new machine no matter what else is set.
    hookshotDefaults = 1;

    # Driven by gestures, so the menu bar item is just clutter.
    hideMenubarIcon = true;
    "NSStatusItem VisibleCC Item-0" = false;

    launchOnLogin = true;

    # Sparkle updates the cask does not know about would fight
    # `homebrew.onActivation.upgrade`.
    SUEnableAutomaticChecks = false;
  }
  // lib.genAttrs unboundShortcuts (_: { });
}
