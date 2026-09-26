{ ... }: { perSystem = { pkgs, ... }: { treefmt = import ../treefmt.nix pkgs; }; }
