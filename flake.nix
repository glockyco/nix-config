{
  description = "Apple Silicon workstation: Determinate Nix + nix-darwin + Home Manager";

  inputs = {
    # Latest stable Nixpkgs. Pinned to the 26.05 train so that nix-darwin and
    # Home Manager (which are release-coupled to it) stay in step; bumping to
    # the next release is a deliberate edit, not a surprise from `nix flake update`.
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.2605";

    nix-darwin = {
      url = "https://flakehub.com/f/nix-darwin/nix-darwin/0.2605";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "https://flakehub.com/f/nix-community/home-manager/0.2605";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Determinate Nix stays the Nix distribution; this module lets nix-darwin
    # cooperate with it instead of fighting over /etc/nix/nix.conf.
    determinate = {
      url = "https://flakehub.com/f/DeterminateSystems/determinate/3";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Declarative Homebrew installation. Its only input is a pinned Homebrew/brew
    # checkout, so there is no nixpkgs to follow.
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    # Oh My Pi (`omp`) and friends.
    #
    # Deliberately NOT `inputs.nixpkgs.follows = "nixpkgs"`: upstream builds and
    # caches every package against its own pinned nixpkgs-unstable. Overriding
    # that both breaks binary-cache hits (omp is a bun + Rust from-source build)
    # and is unsupported against a stable release branch.
    llm-agents.url = "github:numtide/llm-agents.nix";

    # The official Neo project. git.neo-layout.org is authoritative; the
    # github.com/neo-layout mirror is explicitly declared as such and is years stale.
    neo-layout = {
      url = "git+https://git.neo-layout.org/neo/neo-layout.git?shallow=1";
      flake = false;
    };

    # Upstream Karabiner-Elements community rules, including the Neo2 group that
    # https://neo-layout.org/Einrichtung/macOS/ tells you to import by hand.
    karabiner-complex-modifications = {
      url = "github:pqrs-org/KE-complex_modifications";
      flake = false;
    };
  };

  outputs =
    { self, nixpkgs, ... }@inputs:
    let
      system = "aarch64-darwin";

      # The machine is renamed to this by modules/darwin/system.nix, and
      # `darwin-rebuild --flake .` resolves `darwinConfigurations.<LocalHostName>`,
      # so after the first activation the bare form works.
      hostname = "macbook-pro";
      username = "glockyco";

      pkgs = import nixpkgs {
        inherit system;
        overlays = [ self.overlays.default ];
      };
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

        # Exposed so the very first activation, before nix-darwin has ever put
        # darwin-rebuild on PATH, can use the pinned version:
        #   sudo nix run .#darwin-rebuild -- switch --flake .#${hostname}
        inherit (inputs.nix-darwin.packages.${system}) darwin-rebuild;
      };

      checks.${system} = {
        # Builds the whole system closure.
        darwinSystem = self.darwinConfigurations.${hostname}.system;

        # A module that isn't imported isn't an error, it's just absent -- the
        # system still builds and silently does less. That has bitten once
        # (ssh.nix). Assert every module is reachable from its sibling default.nix.
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

      # RFC 166 formatter. Format everything with:
      #   git ls-files -z '*.nix' | xargs -0 nix fmt --
      formatter.${system} = pkgs.nixfmt;
    };
}
