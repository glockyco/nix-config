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

    catppuccin = {
      url = "github:catppuccin/nix";
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
    { self, ... }@inputs:
    let
      system = "aarch64-darwin";

      # `darwin-rebuild --flake .` resolves `darwinConfigurations.<LocalHostName>` after activation.
      hostname = "macbook-pro";
      username = "glockyco";

      # Reuse the package set nix-darwin already instantiated for the system, so
      # the other outputs cannot drift from it and nixpkgs is evaluated once.
      pkgs = self.darwinConfigurations.${hostname}.pkgs;

      treefmtEval = inputs.treefmt-nix.lib.evalModule pkgs ./treefmt.nix;
    in
    {
      darwinConfigurations.${hostname} = inputs.nix-darwin.lib.darwinSystem {
        specialArgs = { inherit inputs hostname username; };
        modules = [ ./modules/darwin ];
      };

      overlays.default = final: _prev: {
        neo-keyboard-layouts = final.callPackage ./packages/neo-keyboard-layouts.nix {
          src = inputs.neo-layout;
        };
      };

      packages.${system} = {
        inherit (pkgs) neo-keyboard-layouts;

        # Expose pinned `darwin-rebuild` for the first activation, before it is on PATH:
        #   sudo nix run .#darwin-rebuild -- switch --flake .#${hostname}
        inherit (inputs.nix-darwin.packages.${system}) darwin-rebuild;
      };

      checks.${system} = {
        darwinSystem = self.darwinConfigurations.${hostname}.system;

        # Fail the check when any tracked file is unformatted.
        formatting = treefmtEval.config.build.check self;

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
      };

      devShells.${system}.default = pkgs.mkShellNoCC {
        packages = [
          inputs.nix-darwin.packages.${system}.darwin-rebuild
          pkgs.git
          self.formatter.${system}
        ];
      };

      # `nix fmt` formats every language listed in ./treefmt.nix, tree-wide.
      formatter.${system} = treefmtEval.config.build.wrapper;
    };
}
