{ lib, ... }:

let
  # Every Rectangle action whose keyboard shortcut is deliberately unbound. An
  # empty dictionary is how Rectangle records "no shortcut", as distinct from an
  # absent key, which means "use the default binding".
  #
  # Window management here is entirely cursor-driven -- Window Throw and
  # Move & Resize -- so every stock shortcut is dead weight, and several of them
  # would sit on chords Neo2 and Karabiner already claim.
  #
  # This is the complete set the app exposes, captured after clearing them in
  # the UI. Regenerate with:
  #
  #   defaults export com.knollsoft.Hookshot - | plutil -convert xml1 -o - -
  #
  # and take every key whose value is an empty dict.
  unboundShortcuts = [
    "almostMaximize"
    "appLeftHalf"
    "appRightHalf"
    "bottomCenterLeftEighth"
    "bottomCenterRightEighth"
    "bottomCenterSixth"
    "bottomHalf"
    "bottomLeft"
    "bottomLeftSixth"
    "bottomLeftThird"
    "bottomRight"
    "bottomRightNinth"
    "bottomRightSixth"
    "bottomRightThird"
    "bottomVerticalThird"
    "bottomVerticalTwoThirds"
    "cascadeAll"
    "cascadeApp"
    "center"
    "centerHalf"
    "centerThird"
    "centerThreeFourths"
    "centerTwoThirds"
    "fillBottomLeft"
    "fillBottomRight"
    "fillLeft"
    "fillRight"
    "fillTopLeft"
    "fillTopRight"
    "firstFifth"
    "firstFourth"
    "firstSixth"
    "firstThird"
    "firstThreeFourths"
    "firstTwoThirds"
    "larger"
    "largerHeight"
    "largerWidth"
    "lastFourth"
    "lastThird"
    "lastThreeFourths"
    "lastTwoThirds"
    "leftHalf"
    "maximize"
    "maximizeHeight"
    "middleRightNinth"
    "middleVerticalThird"
    "moveDown"
    "moveLeft"
    "moveUp"
    "nextDisplay"
    "nextDisplayRatio"
    "nudgeRight"
    "nudgeUp"
    "prevSpace"
    "previousDisplay"
    "restore"
    "rightHalf"
    "secondFifth"
    "secondFourth"
    "smaller"
    "smallerWidth"
    "snapTopLeft"
    "thirdFifth"
    "thirdFourth"
    "topCenterLeftEighth"
    "topCenterSixth"
    "topHalf"
    "topLeft"
    "topLeftEighth"
    "topLeftSixth"
    "topLeftThird"
    "topRight"
    "topRightSixth"
    "topRightThird"
    "topVerticalThird"
    "topVerticalTwoThirds"
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
    # The decisive one, established by experiment rather than documentation.
    # The previous machine had this set and its cursor-movement features worked;
    # a fresh install here did not have it and Move & Resize was inert. Setting
    # it fixed that. The key is undocumented, so why it has that effect -- and
    # whether it relates to the Hookshot-era licence also present on the old
    # machine -- is not established.
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
