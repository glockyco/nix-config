{ config, pkgs, ... }:

{
  # Clones live at ~/src/<host>/<owner>/<repo>, which `ghq get <url>` derives
  # from the URL. The point is the owner segment: forks and their upstreams have
  # the same repository name, so a flat directory cannot hold both without hand
  # -picked suffixes. Namespacing by owner makes that collision impossible
  # instead of merely unlikely.
  #
  # The depth costs nothing to navigate -- zoxide and fzf are already set up in
  # modules/home/cli.nix, and `ghq list --full-path` feeds a picker directly.
  #
  # Nothing here depends on ghq staying: the layout is plain directories, and
  # `ghq.root` is only read by ghq itself.
  home.packages = [ pkgs.ghq ];

  programs.git.settings.ghq.root = "${config.home.homeDirectory}/src";
}
