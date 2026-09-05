{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  inherit (import ../shared) tailnetDnsDomain;
  macHost = inputs.self.darwinConfigurations.macbook-pro.config.host;
  macTailnetName = "${macHost.name}.${tailnetDnsDomain}";
  tailnetBuilderCheck = pkgs.callPackage ../../packages/tailnet-builder-check.nix {
    hostName = macHost.name;
  };
  macBuilder = lib.findFirst (
    machine: machine.hostName == macHost.name
  ) (throw "the Mac SSH client requires its declared remote builder") config.nix.buildMachines;
in
{
  # Zed's Windows UI starts language servers in its WSL remote process. Keep
  # nixd in the system closure so that process can resolve it without entering
  # a repository development shell.
  environment.systemPackages = [
    pkgs.nixd
    tailnetBuilderCheck
  ];

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

  # The Nix daemon and release commands use the same root-only credential.
  programs.ssh.knownHosts.${macHost.name} = {
    hostNames = [
      macHost.name
      macTailnetName
    ];
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKVMJe00KQ0ozyXyJ+PB5BllhI5tckDKKCVpJnM2Kw+3";
  };
  programs.ssh.extraConfig = ''
    Host ${macBuilder.hostName}
      HostName ${macTailnetName}
      User ${macBuilder.sshUser}
      IdentityFile ${macBuilder.sshKey}
      IdentitiesOnly yes
      StrictHostKeyChecking yes
      UserKnownHostsFile /dev/null
      BatchMode yes
      ConnectTimeout 8
      ControlMaster no
      ControlPath none
  '';

  # `modules/home/shell.nix` configures zsh for the user. Enabling it here
  # registers zsh as a login shell, which `users.users.<name>.shell` needs.
  programs.zsh.enable = true;
}
