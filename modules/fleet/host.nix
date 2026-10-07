{ lib, ... }:

let
  inherit (lib) mkOption types;
  nonEmptyString = types.strMatching ".+";
  absolutePath = types.strMatching "/.+";
  nullableString = types.nullOr nonEmptyString;
  uniqueNonNull =
    field: applications:
    let
      values = builtins.filter (value: value != null) (
        map (application: application.${field}) applications
      );
    in
    builtins.length values == builtins.length (lib.unique values);
in
{
  options.host = {
    name = mkOption {
      type = nonEmptyString;
      description = "Stable host name used by generated system outputs.";
    };

    system = mkOption {
      type = nonEmptyString;
      description = "System architecture and operating system of this host.";
    };

    kind = mkOption {
      type = types.enum [
        "darwin"
        "nixos"
      ];
      description = "System configuration kind of this host.";
    };

    username = mkOption {
      type = nonEmptyString;
      description = "Interactive user managed by the host configuration.";
    };

    homeDirectory = mkOption {
      type = absolutePath;
      description = "Interactive user's home from shared platform facts.";
    };

    roles =
      lib.genAttrs
        [
          "desktop"
          "postgresql"
          "containerClient"
          "airClient"
          "wslWorkstation"
        ]
        (
          role:
          mkOption {
            type = types.bool;
            default = false;
            description = "Shared selection of the ${role} role.";
          }
        );

    importedRoles =
      lib.genAttrs
        [
          "desktop"
          "postgresql"
          "containerClient"
          "airClient"
          "wslWorkstation"
        ]
        (
          role:
          mkOption {
            type = types.bool;
            default = false;
            description = "Whether an explicit import enables the ${role} role.";
          }
        );
    displayName = mkOption {
      type = nullableString;
      default = null;
      description = "User-visible computer name, when the platform sets one.";
    };

    timeZone = mkOption {
      type = nullableString;
      default = null;
      description = "Time zone explicitly configured for this host.";
    };

    locale = {
      timeCategory = mkOption {
        type = nullableString;
        default = null;
        description = "Explicit LC_TIME locale, when supported by the host.";
      };

      measurementCategory = mkOption {
        type = nullableString;
        default = null;
        description = "Explicit LC_MEASUREMENT locale, when supported by the host.";
      };

      use24HourClock = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Explicit 24-hour clock preference, when supported by the host.";
      };

      useMetric = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Explicit metric measurement preference, when supported by the host.";
      };
    };

    paths = {
      configurationCheckout = mkOption {
        type = types.nullOr absolutePath;
        default = null;
        description = "Absolute checkout location for host configuration commands.";
      };

      screenshots = mkOption {
        type = types.nullOr absolutePath;
        default = null;
        description = "Absolute screenshot directory, when configured.";
      };

      repositoryRoot = mkOption {
        type = absolutePath;
        description = "Root for ghq checkouts from shared platform facts.";
      };
    };

    git = {
      authorName = mkOption {
        type = nonEmptyString;
        description = "Name used to author Git commits.";
      };

      defaultEmail = mkOption {
        type = nonEmptyString;
        description = "Default email address used to author Git commits.";
      };

      githubNoReplyEmail = mkOption {
        type = nonEmptyString;
        description = "GitHub no-reply email address used for personal repositories.";
      };
    };

    darwin = {
      applications = mkOption {
        type = types.listOf (
          types.submodule {
            options = {
              cask = mkOption {
                type = nullableString;
                default = null;
                description = "Homebrew cask that installs this application.";
              };

              appPath = mkOption {
                type = types.nullOr absolutePath;
                default = null;
                description = "Absolute application bundle path used in the Dock.";
              };

              dockPosition = mkOption {
                type = types.nullOr types.ints.positive;
                default = null;
                description = "One-based position in the ordered Dock application list.";
              };

              rationale = mkOption {
                type = nonEmptyString;
                description = "Reason this application belongs in the host inventory.";
              };
            };
          }
        );
        default = [ ];
        apply =
          applications:
          assert lib.assertMsg (uniqueNonNull "cask" applications)
            "host.darwin.applications has duplicate casks";
          assert lib.assertMsg (uniqueNonNull "appPath" applications)
            "host.darwin.applications has duplicate app paths";
          assert lib.assertMsg (uniqueNonNull "dockPosition" applications)
            "host.darwin.applications has duplicate Dock positions";
          assert lib.assertMsg (builtins.all
            (
              application:
              (application.cask != null || application.appPath != null)
              && (application.dockPosition == null || application.appPath != null)
            )
            applications
          ) "host.darwin.applications needs a cask or app path and a path for each Dock position";
          applications;
        description = "Homebrew casks and ordered Dock application bundles.";
      };

      containerProfile = mkOption {
        type = types.nullOr (
          types.submodule {
            options = {
              cpu = mkOption {
                type = types.ints.positive;
                description = "Colima virtual-machine CPU count.";
              };

              memory = mkOption {
                type = types.ints.positive;
                description = "Colima virtual-machine memory in GiB.";
              };

              disk = mkOption {
                type = types.ints.positive;
                description = "Colima virtual-machine disk in GiB.";
              };

              mounts = mkOption {
                type = types.listOf (
                  types.submodule {
                    options = {
                      location = mkOption {
                        type = absolutePath;
                        description = "Absolute host directory mounted in the Colima VM.";
                      };

                      writable = mkOption {
                        type = types.bool;
                        description = "Whether the Colima mount permits writes.";
                      };
                    };
                  }
                );
                apply =
                  mounts:
                  assert lib.assertMsg (mounts != [ ]) "host.darwin.containerProfile.mounts must not be empty";
                  mounts;
                description = "Host directories mounted in the Colima VM.";
              };
            };
          }
        );
        default = null;
        description = "Host-specific Colima virtual-machine resources and mounts.";
      };
    };

    build.logicalCores = mkOption {
      type = types.nullOr types.ints.positive;
      default = null;
      description = "Measured logical CPU count when this host serves as a remote builder.";
    };

    tailnet = {
      tag = mkOption {
        type = types.strMatching "^tag:[a-z0-9-]+$";
        description = "Stable tailnet policy tag assigned to this host.";
      };

      reachable = mkOption {
        type = types.bool;
        default = true;
        description = "Whether tailnet policy may name this host as a destination.";
      };
    };
  };
}
