{
  coreutils,
  lib,
  nvd,
  writeShellApplication,
  configurationCheckout ? null,
  darwinRebuild ? null,
}:
writeShellApplication {
  name = "darwin-switch";
  runtimeInputs = [
    coreutils
    nvd
  ];
  passthru = { inherit configurationCheckout; };
  meta = {
    description = "Switch the Darwin system then apply chezmoi as the user and report the closure diff";
    mainProgram = "darwin-switch";
    platforms = lib.platforms.darwin;
  };
  text = ''
    if [ "$EUID" -eq 0 ]; then
      printf '%s\n' 'darwin-switch: run as the ordinary user, not with sudo' >&2
      exit 64
    fi
    rebuild="''${DARWIN_SWITCH_REBUILD:-${
      if darwinRebuild == null then
        "/run/current-system/sw/bin/darwin-rebuild"
      else
        lib.getExe darwinRebuild
    }}"
    sudo_command="''${DARWIN_SWITCH_SUDO:-/usr/bin/sudo}"
    readlink_command="''${DARWIN_SWITCH_READLINK:-readlink}"
    nvd_command="''${DARWIN_SWITCH_NVD:-nvd}"
    ${
      if configurationCheckout == null then
        ''
          source=$(chezmoi source-path)
          checkout=$(dirname "$source")
        ''
      else
        ''
          checkout=${lib.escapeShellArg configurationCheckout}
        ''
    }
    before=$("$readlink_command" -f /run/current-system)
    if "$sudo_command" "$rebuild" switch --flake "$checkout" "$@"; then
      :
    else
      status=$?
      printf '%s\n' 'darwin-switch: system switch failed; user apply was not run' >&2
      exit "$status"
    fi
    # Stable profile links now point at the selected generation. Resolve chezmoi
    # and every helper afresh rather than keeping the invoking shell's hash table.
    user_name=$(id -un)
    PATH="/etc/profiles/per-user/$user_name/bin:/run/current-system/sw/bin:$PATH"
    export PATH
    hash -r
    if chezmoi apply; then
      :
    else
      status=$?
      printf '%s\n' 'darwin-switch: user apply failed after system switch; recover system and user state separately' >&2
      exit "$status"
    fi
    after=$("$readlink_command" -f /run/current-system)
    if [ "$before" = "$after" ]; then
      printf '%s\n' 'darwin-switch: closure unchanged'
    else
      "$nvd_command" diff "$before" "$after"
    fi
  '';
}
