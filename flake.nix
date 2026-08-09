{
  description = "Apple Silicon workstation: Determinate Nix + nix-darwin + Home Manager";

  inputs = {
    # Pin nixpkgs to 26.05 to keep nix-darwin and Home Manager on the same release.
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.2605";

    nix-darwin = {
      url = "https://flakehub.com/f/nix-darwin/nix-darwin/0.2605";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "https://flakehub.com/f/nix-community/home-manager/0.2605";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Determinate owns `/etc/nix/nix.conf`; coordinate it with nix-darwin through this module.
    determinate = {
      url = "https://flakehub.com/f/DeterminateSystems/determinate/3";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-parts = {
      url = "github:hercules-ci/flake-parts";

      # flake-parts consumes nixpkgs-lib rather than nixpkgs; follow the pinned library explicitly.
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Do not set `inputs.nixpkgs.follows`: upstream pins nixpkgs-unstable for its packages and cache.
    # Overriding it breaks cache hits and is unsupported on this stable release branch.
    llm-agents.url = "github:numtide/llm-agents.nix";

    # Use the official Neo repository; the GitHub mirror is stale.
    neo-layout = {
      url = "git+https://git.neo-layout.org/neo/neo-layout.git?shallow=1";
      flake = false;
    };

    # Include upstream Karabiner rules, including the Neo2 group from `neo-layout.org/Einrichtung/macOS/`.
    karabiner-complex-modifications = {
      url = "github:pqrs-org/KE-complex_modifications";
      flake = false;
    };
  };

  outputs =
    inputs@{ self, ... }:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "aarch64-darwin"
        "x86_64-linux"
      ];

      imports = [ inputs.treefmt-nix.flakeModule ];

      flake = {
        darwinConfigurations.macbook-pro = import ./hosts/macbook-pro { inherit inputs; };

        overlays.default = final: _prev: {
          neo-keyboard-layouts = final.callPackage ./packages/neo-keyboard-layouts.nix {
            src = inputs.neo-layout;
          };
        };
      };

      perSystem =
        {
          config,
          lib,
          system,
          ...
        }:
        let
          isDarwin = system == "aarch64-darwin";

          # Reuse the package set nix-darwin already instantiated for the system, so
          # the other outputs cannot drift from it and nixpkgs is evaluated once.
          pkgs =
            if isDarwin then
              self.darwinConfigurations.macbook-pro.pkgs
            else
              inputs.nixpkgs.legacyPackages.${system}.extend self.overlays.default;
        in
        {
          # `nix fmt` formats every language listed in ./treefmt.nix, tree-wide.
          # Fail the check when any tracked file is unformatted.
          treefmt = import ./treefmt.nix pkgs;

          # flake-parts' default package set does not include this flake's overlay.
          # Use the Darwin package set above, or extend the per-system package set on Linux.
          _module.args.pkgs = pkgs;

          packages = {
            inherit (pkgs) neo-keyboard-layouts;
          }
          // lib.optionalAttrs isDarwin {
            # Expose pinned `darwin-rebuild` for the first activation, before it is on PATH:
            #   sudo nix run .#darwin-rebuild -- switch --flake .#macbook-pro
            inherit (inputs.nix-darwin.packages.${system}) darwin-rebuild;
          };

          checks = {
            # An unimported module is absent rather than an error.
            # Assert every module is reachable from its sibling `default.nix`.
            moduleImports = pkgs.runCommand "check-module-imports" { } ''
              cd ${./modules}
              missing=
              for dir in */; do
                for f in "$dir"*.nix; do
                  base=''${f#"$dir"}
                  if [ "$base" != default.nix ] && ! grep -qF "./$base" "$dir/default.nix"; then
                    missing="$missing $f"
                  fi
                done
              done
              if [ -n "$missing" ]; then
                echo "not imported by their sibling default.nix:$missing" >&2
                exit 1
              fi
              touch $out
            '';
          }
          // lib.optionalAttrs isDarwin {
            darwinSystem = self.darwinConfigurations.macbook-pro.system;
          };

          devShells = lib.optionalAttrs isDarwin {
            default = pkgs.mkShellNoCC {
              packages = [
                inputs.nix-darwin.packages.${system}.darwin-rebuild
                pkgs.git
                pkgs.dnscontrol
                config.treefmt.build.wrapper
              ];
            };
          };
        };
    };
}
