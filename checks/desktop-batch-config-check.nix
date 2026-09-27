{
  coreutils,
  gnugrep,
  homeConfiguration,
  openssh,
  runCommand,
}:

let
  sshConfig = homeConfiguration.home.file.".ssh/config".source;
  destination = homeConfiguration.programs.ssh.settings.desktop.data;
in
runCommand "check-desktop-batch-configuration"
  {
    nativeBuildInputs = [
      coreutils
      gnugrep
      openssh
    ];
  }
  ''
    for endpoint in desktop desktop-batch; do
      ssh -G -F ${sshConfig} "$endpoint" > "$TMPDIR/$endpoint"
      config="$TMPDIR/$endpoint"
      grep -qFx 'user ${destination.User}' "$config"
      grep -qFx 'hostname ${destination.HostName}' "$config"
      grep -qFx 'stdinnull no' "$config"
      grep -qFx 'stricthostkeychecking true' "$config"
      grep -qFx 'passwordauthentication no' "$config"
      grep -qFx 'kbdinteractiveauthentication no' "$config"
      grep -qFx 'updatehostkeys false' "$config"
      grep -qFx 'globalknownhostsfile /dev/null' "$config"
      pin=$(sed -n 's/^userknownhostsfile //p' "$config")
      case "$pin" in
        /nix/store/*-desktop-known-hosts) ;;
        *) echo 'desktop must use only its immutable host pin' >&2; exit 1 ;;
      esac
      ssh-keygen -F desktop -f "$pin" > "$TMPDIR/pinned-key"
      ssh-keygen -lf "$TMPDIR/pinned-key" |
        grep -qF 'SHA256:ZYFVPT8M8AJI7Vmq63k018DCGIIJKA8atz3xQ6TI4Lw'
    done

    grep -qFx 'batchmode no' "$TMPDIR/desktop"
    grep -qFx 'controlmaster auto' "$TMPDIR/desktop"
    grep -qFx 'requesttty auto' "$TMPDIR/desktop"
    grep -qFx 'connecttimeout none' "$TMPDIR/desktop"
    grep -qFx 'controlpersist 3600' "$TMPDIR/desktop"

    grep -qFx 'batchmode yes' "$TMPDIR/desktop-batch"
    grep -qFx 'controlmaster false' "$TMPDIR/desktop-batch"
    grep -qFx 'requesttty false' "$TMPDIR/desktop-batch"
    grep -qFx 'connecttimeout 8' "$TMPDIR/desktop-batch"
    grep -qFx 'controlpersist no' "$TMPDIR/desktop-batch"
    ! grep -q '^controlpath ' "$TMPDIR/desktop-batch"

    touch "$out"
  ''
