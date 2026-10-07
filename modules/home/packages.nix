{ lib, pkgs, ... }:

{
  # Upstream OMP and its personal plugin are installed outside Nix (official
  # installer, plugin manager); these are the ordinary tools they call.
  # The plugin selects a language server only when its executable resolves, so
  # a host without one simply never starts it. Texlab comes with `tex.nix`.
  # Herdr stays available as a secondary multiplexer beside Tern; its OMP
  # integration is installed on demand with `herdr integration install omp`.
  home.packages = [
    pkgs.uv
    pkgs.herdr
    pkgs.openspec
    pkgs.plannotator
    pkgs.markdown-oxide
    pkgs.nixd
    pkgs.pyright
    pkgs.svelte-language-server
    pkgs.typescript-language-server
  ]
  # C# and Unity work happens only on the Mac.
  ++ lib.optional pkgs.stdenv.hostPlatform.isDarwin pkgs.roslyn-language-server;

  # The official OMP installer's default location.
  home.sessionPath = [ "$HOME/.local/bin" ];
}
