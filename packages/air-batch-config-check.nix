{
  coreutils,
  gnugrep,
  homeConfiguration,
  openssh,
  runCommand,
}:

let
  settings = homeConfiguration.programs.ssh.settings;
  air = settings.air.data;
  airBatch = settings."air-batch".data;
  defaults = settings."*".data;
  sshConfig = homeConfiguration.home.file.".ssh/config".source;
in

assert air.HostName == airBatch.HostName;
assert air.User == airBatch.User;
assert
  builtins.removeAttrs air [ "header" ] == {
    HostName = "MacBook-Air-von-ISYS.local";
    User = "joaichberger";
  };
assert airBatch.BatchMode == "yes";
assert airBatch.RequestTTY == "no";
assert airBatch.ControlMaster == "no";
assert airBatch.ControlPath == "none";
assert airBatch.ControlPersist == "no";
assert airBatch.ConnectTimeout == 8;
assert !(airBatch ? StdinNull);
assert defaults.ControlMaster == "auto";
assert defaults.ControlPersist == "1h";
runCommand "check-air-batch-configuration"
  {
    nativeBuildInputs = [
      coreutils
      gnugrep
      openssh
    ];
  }
  ''
    ssh -G -F ${sshConfig} air > $TMPDIR/air
    ssh -G -F ${sshConfig} air-batch > $TMPDIR/air-batch

    grep -qFx 'user joaichberger' $TMPDIR/air
    grep -qFx 'hostname macbook-air-von-isys.local' $TMPDIR/air
    grep -qFx 'batchmode no' $TMPDIR/air
    grep -qFx 'controlmaster auto' $TMPDIR/air
    grep -qFx 'requesttty auto' $TMPDIR/air
    grep -qFx 'stdinnull no' $TMPDIR/air
    grep -qFx 'connecttimeout none' $TMPDIR/air
    grep -qFx 'controlpersist 3600' $TMPDIR/air

    grep -qFx 'user joaichberger' $TMPDIR/air-batch
    grep -qFx 'hostname macbook-air-von-isys.local' $TMPDIR/air-batch
    grep -qFx 'batchmode yes' $TMPDIR/air-batch
    grep -qFx 'controlmaster false' $TMPDIR/air-batch
    grep -qFx 'requesttty false' $TMPDIR/air-batch
    grep -qFx 'stdinnull no' $TMPDIR/air-batch
    grep -qFx 'connecttimeout 8' $TMPDIR/air-batch
    grep -qFx 'controlpersist no' $TMPDIR/air-batch
    ! grep -q '^controlpath ' $TMPDIR/air-batch

    touch $out
  ''
