{
  programs.gh = {
    enable = true;

    settings = {
      git_protocol = "ssh";

      # `editor` stays at its empty default, which makes `gh` read the
      # environment, so `gh` and `git` both follow `EDITOR`. Naming an
      # application here would be false on a host that does not install it.
    };
  };
}
