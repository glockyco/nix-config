{
  coreutils,
  gnugrep,
  homeConfiguration,
  openssh,
  runCommand,
}:

let
  sshConfig = homeConfiguration.home.file.".ssh/config".source;
in
runCommand "check-batch-configuration"
  {
    nativeBuildInputs = [
      coreutils
      gnugrep
      openssh
    ];
  }
  ''
    for host in air desktop; do
      ssh -G -F ${sshConfig} "$host" > "$TMPDIR/$host"
      ssh -G -F ${sshConfig} "$host-batch" > "$TMPDIR/$host-batch"

      case "$host" in
        air) user=joaichberger; destination=macbook-air ;;
        desktop) user=User; destination=desktop ;;
      esac

      for endpoint in "$host" "$host-batch"; do
        grep -qFx "user $user" "$TMPDIR/$endpoint"
        grep -qFx "hostname $destination" "$TMPDIR/$endpoint"
        grep -qFx 'stdinnull no' "$TMPDIR/$endpoint"
      done

      grep -qFx 'batchmode no' "$TMPDIR/$host"
      grep -qFx 'controlmaster auto' "$TMPDIR/$host"
      grep -qFx 'requesttty auto' "$TMPDIR/$host"
      grep -qFx 'connecttimeout none' "$TMPDIR/$host"
      grep -qFx 'controlpersist 3600' "$TMPDIR/$host"

      grep -qFx 'batchmode yes' "$TMPDIR/$host-batch"
      grep -qFx 'controlmaster false' "$TMPDIR/$host-batch"
      grep -qFx 'requesttty false' "$TMPDIR/$host-batch"
      grep -qFx 'connecttimeout 8' "$TMPDIR/$host-batch"
      grep -qFx 'controlpersist no' "$TMPDIR/$host-batch"
      ! grep -q '^controlpath ' "$TMPDIR/$host-batch"
    done

    for endpoint in desktop desktop-batch; do
      config="$TMPDIR/$endpoint"
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

    touch $out
  ''
