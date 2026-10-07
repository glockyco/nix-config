{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (import ../../../shared) tailnetDnsDomain;
  builderHost =
    lib.findFirst (host: host.name != config.host.name && host.build.logicalCores != null)
      (throw "the SSH client requires a declared remote builder")
      (builtins.attrValues config.fleet.hosts);
  builderTailnetName = "${builderHost.name}.${tailnetDnsDomain}";
  tailnetBuilderCheck = pkgs.tailnet-builder-check.override { hostName = builderHost.name; };
  builder = lib.findFirst (
    machine: machine.hostName == builderHost.name
  ) (throw "the SSH client requires its declared remote builder") config.nix.buildMachines;
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

  # The Nix daemon and release commands use the same root-only credential.
  programs.ssh.knownHosts.${builderHost.name} = {
    hostNames = [
      builderHost.name
      builderTailnetName
    ];
    publicKey =
      (builtins.fromTOML (builtins.readFile ../../../../home/.chezmoidata/ssh.toml))
      .ssh.hostKeys.${builderHost.name}.publicKey;
  };
  programs.ssh.extraConfig = ''
    Match originalhost ${builder.hostName} localuser root
      HostName ${builderTailnetName}
      User ${builder.sshUser}
      IdentityFile ${builder.sshKey}
      IdentitiesOnly yes
      StrictHostKeyChecking yes
      UserKnownHostsFile /dev/null
      BatchMode yes
      ConnectTimeout 8
      ControlMaster no
      ControlPath none

    Match all
  '';

}
