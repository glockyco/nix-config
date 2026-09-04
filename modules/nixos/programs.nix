{ pkgs, ... }:

{
  # Zed's Windows UI starts language servers in its WSL remote process. Keep
  # nixd in the system closure so that process can resolve it without entering
  # a repository development shell.
  environment.systemPackages = [ pkgs.nixd ];

  # Project work uses prebuilt executables that expect a conventional dynamic
  # loader: .NET tooling, Unity, game loader toolchains, and OMP's managed
  # Chromium. `nix-ld` supplies the loader and the browser ABI without making
  # Nix responsible for OMP's downloaded browser or writable runtime state.
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      alsa-lib
      at-spi2-core
      cairo
      cups
      dbus
      expat
      glib
      libgbm
      libX11
      libXcomposite
      libXdamage
      libXext
      libXfixes
      libXrandr
      libxcb
      libxkbcommon
      nspr
      nss
      pango
    ];
  };

  # `EDITOR` must name a program this host provides, and the portable user
  # modules carry no editor: the Darwin host uses Zed, and on this machine the
  # Windows layer owns that. `nano` is not in the NixOS default package set, so
  # it is declared here rather than assumed.
  programs.nano.enable = true;

  # `modules/home/shell.nix` configures zsh for the user. Enabling it here
  # registers zsh as a login shell, which `users.users.<name>.shell` needs.
  programs.zsh.enable = true;
}
