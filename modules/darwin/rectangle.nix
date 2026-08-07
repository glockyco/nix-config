{ lib, ... }:

let
  # Empty dictionaries mean "no shortcut"; absent keys use Rectangle defaults.
  # This list was captured from Rectangle's UI after clearing all shortcuts.
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
  # Rectangle Pro retains bundle id `com.knollsoft.Hookshot` from Hookshot.
  # Exclude `Paddle-*`, `fld`, and `displayCache`: the first two contain licence
  # data; `displayCache` is machine-specific.
  # Rectangle rewrites preferences on quit; restart it after changing these values.
  system.defaults.CustomUserPreferences."com.knollsoft.Hookshot" = {
    hookshotDefaults = 1;

    hideMenubarIcon = true;
    "NSStatusItem VisibleCC Item-0" = false;

    launchOnLogin = true;

    SUEnableAutomaticChecks = false;
  }
  // lib.genAttrs unboundShortcuts (_: { });
}
