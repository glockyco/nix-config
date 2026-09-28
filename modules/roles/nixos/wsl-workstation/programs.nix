{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (import ../../../shared) tailnetDnsDomain tailnetPeers;
  builderHost =
    lib.findFirst (host: host.name != config.host.name && host.build.logicalCores != null)
      (throw "the SSH client requires a declared remote builder")
      (builtins.attrValues config.fleet.hosts);
  builderTailnetName = "${builderHost.name}.${tailnetDnsDomain}";
  # The user-owned key, never the root-owned Mac builder credential, so the
  # desktop and the Mac can each revoke this host without touching remote builds.
  userIdentityFile = "/home/${config.host.username}/.ssh/id_ed25519";

  # The desktop's Windows account owns its own name, so it cannot be derived
  # from this host's user. The peer declaration is the source for the node name.
  desktopHost =
    assert tailnetPeers ? desktop;
    {
      name = "desktop";
      account = "User";
    };
  desktopTailnetName = "${desktopHost.name}.${tailnetDnsDomain}";
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
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKVMJe00KQ0ozyXyJ+PB5BllhI5tckDKKCVpJnM2Kw+3";
  };
  # The desktop is an unmanaged tailnet peer whose Windows account name differs
  # from this host's user, so its endpoints need their own block. The pin is the
  # host key the owner verified at the desktop's console; its fingerprint is
  # SHA256:ZYFVPT8M8AJI7Vmq63k018DCGIIJKA8atz3xQ6TI4Lw. This host reaches the
  # desktop outbound only, which leaves its own no-inbound boundary intact.
  programs.ssh.knownHosts.${desktopHost.name} = {
    hostNames = [
      desktopHost.name
      desktopTailnetName
    ];
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN/+XoGCH3MVvNQuvVfjmidMk5mEa+gqs84C00s6DiEt";
  };
  programs.ssh.extraConfig = ''
    Host ${desktopHost.name} ${desktopHost.name}-batch
      HostName ${desktopTailnetName}
      User ${desktopHost.account}
      IdentityFile ${userIdentityFile}
      IdentitiesOnly yes
      StrictHostKeyChecking yes
      PasswordAuthentication no
      KbdInteractiveAuthentication no
      UpdateHostKeys no

    # An unattended command must exit with its remote process rather than
    # inherit an interactive connection, matching the Darwin host's split.
    Host ${desktopHost.name}-batch
      BatchMode yes
      RequestTTY no
      ConnectTimeout 8
      ControlMaster no
      ControlPath none

    # Root, and therefore the Nix daemon, resolves the builder name to the
    # root-only builder key. IdentityFile values accumulate across blocks, so
    # the user endpoints below exclude root rather than rely on block order.
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

    Match originalhost ${builder.hostName},${builder.hostName}-batch !localuser root
      HostName ${builderTailnetName}
      User ${builder.sshUser}
      IdentityFile ${userIdentityFile}
      IdentitiesOnly yes
      StrictHostKeyChecking yes
      PasswordAuthentication no
      KbdInteractiveAuthentication no
      UpdateHostKeys no

    Match originalhost ${builder.hostName}-batch !localuser root
      BatchMode yes
      RequestTTY no
      ConnectTimeout 8
      ControlMaster no
      ControlPath none

    Match all
  '';

  # `modules/home/shell.nix` configures zsh for the user. Enabling it here
  # registers zsh as a login shell, which `users.users.<name>.shell` needs.
  programs.zsh.enable = true;
}
