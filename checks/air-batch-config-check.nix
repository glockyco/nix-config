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
    ssh -G -F ${sshConfig} air > "$TMPDIR/air"
    ssh -G -F ${sshConfig} air-batch > "$TMPDIR/air-batch"

    for endpoint in air air-batch; do
      grep -qFx 'user joaichberger' "$TMPDIR/$endpoint"
      grep -qFx 'hostname macbook-air' "$TMPDIR/$endpoint"
      grep -qFx 'stdinnull no' "$TMPDIR/$endpoint"
    done

    grep -qFx 'batchmode no' "$TMPDIR/air"
    grep -qFx 'controlmaster auto' "$TMPDIR/air"
    grep -qFx 'requesttty auto' "$TMPDIR/air"
    grep -qFx 'connecttimeout none' "$TMPDIR/air"
    grep -qFx 'controlpersist 3600' "$TMPDIR/air"

    grep -qFx 'batchmode yes' "$TMPDIR/air-batch"
    grep -qFx 'controlmaster false' "$TMPDIR/air-batch"
    grep -qFx 'requesttty false' "$TMPDIR/air-batch"
    grep -qFx 'connecttimeout 8' "$TMPDIR/air-batch"
    grep -qFx 'controlpersist no' "$TMPDIR/air-batch"
    ! grep -q '^controlpath ' "$TMPDIR/air-batch"

    touch $out
  ''
