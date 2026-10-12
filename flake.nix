{
  description = "Fleet workstations: native Nix systems and portable chezmoi user configuration";

  # This flake declares no `nixConfig`. Each host declares the Numtide
  # substituter and its trusted public key in system scope, and Nix ignores a
  # flake-provided key for a user who is not in `trusted-users`. A machine that
  # has neither host configuration passes both values as command-line flags.
  inputs = {
    # Keep the native platform configurations on the same nixpkgs release.
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.2605";

    nix-darwin = {
      url = "https://flakehub.com/f/nix-darwin/nix-darwin/0.2605";
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

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Do not set `inputs.nixpkgs.follows`: upstream pins nixpkgs-unstable for its packages and cache.
    # Overriding it breaks cache hits and is unsupported on this stable release branch.
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.flake-parts.follows = "flake-parts";
    };

    # Pin Plannotator releases independently; retain the vendor's own transitive inputs.
    plannotator-packages.url = "github:numtide/llm-agents.nix/b1c9a31450a814e50cddc3ab683b05c1dff7bb01";

    # Include upstream Karabiner rules, including the Neo2 group from `neo-layout.org/Einrichtung/macOS/`.
    karabiner-complex-modifications = {
      url = "github:pqrs-org/KE-complex_modifications";
      flake = false;
    };
  };

  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } ./flake-modules;
}
