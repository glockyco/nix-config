{ pkgs }:
# Ordinary tools share the host's overlay-extended package set. OMP and its
# runtime plugin remain installer/plugin-manager owned, including Herdr's
# optional integration installation.
with pkgs;
[
  git
  git-lfs
  delta
  gh
  ghq
  uv
  herdr
  openspec
  plannotator
  markdown-oxide
  nixd
  pyright
  svelte-language-server
  typescript-language-server
  fzf
  zoxide
  ripgrep
  fd
  bat
  eza
  starship
  typst
  tinymist
  texliveFull
  texlab
  poppler-utils
  (python3.withPackages (ps: [ ps.pygments ]))
  aspell
  aspellDicts.en
  chezmoi
]
