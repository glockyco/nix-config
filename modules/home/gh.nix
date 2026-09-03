{ lib, ... }:

{
  programs.gh = {
    enable = true;

    settings = {
      # A host that holds a GitHub key uses it. A host that holds none declares
      # `https` instead, so this value is a default rather than a fixed choice.
      git_protocol = lib.mkDefault "ssh";

      # `editor` stays at its empty default, which makes `gh` read the
      # environment, so `gh` and `git` both follow `EDITOR`. Naming an
      # application here would be false on a host that does not install it.
    };
  };
}
