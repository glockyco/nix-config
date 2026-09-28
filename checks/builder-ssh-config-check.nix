{
  coreutils,
  gnugrep,
  gnused,
  openssh,
  runCommand,
  # The rendered system client configuration.
  sshConfig,
  # The declared remote build machine and the interactive user's key.
  builder,
  userIdentityFile,
}:

# Root, and therefore the Nix daemon, must resolve the builder to its root-only
# key; every other user must resolve the same name to the user's own key. The
# sandbox cannot run as root, so a copy that matches the build user as root
# proves the root branch.
runCommand "check-builder-ssh-configuration"
  {
    nativeBuildInputs = [
      coreutils
      gnugrep
      gnused
      openssh
    ];
  }
  ''
    # systemd's included proxy snippet only matches unix/ and vsock/ hosts, and
    # OpenSSH rejects its store ownership inside the build sandbox.
    sed '/^Include .*ssh_config\.d/d' ${sshConfig} > "$TMPDIR/ssh_config"

    for endpoint in ${builder.hostName} ${builder.hostName}-batch; do
      config="$TMPDIR/$endpoint"
      ssh -G -F "$TMPDIR/ssh_config" "$endpoint" > "$config"
      grep -qFx 'user ${builder.sshUser}' "$config"
      grep -qFx 'identityfile ${userIdentityFile}' "$config"
      grep -qFx 'identitiesonly yes' "$config"
      grep -qFx 'stricthostkeychecking true' "$config"
      grep -qFx 'passwordauthentication no' "$config"
      grep -qFx 'kbdinteractiveauthentication no' "$config"
      test "$(grep -c '^identityfile ' "$config")" = 1
    done

    grep -qFx 'batchmode no' "$TMPDIR/${builder.hostName}"
    grep -qFx 'requesttty auto' "$TMPDIR/${builder.hostName}"

    batch="$TMPDIR/${builder.hostName}-batch"
    grep -qFx 'batchmode yes' "$batch"
    grep -qFx 'controlmaster false' "$batch"
    grep -qFx 'requesttty false' "$batch"
    grep -qFx 'connecttimeout 8' "$batch"
    grep -qFx 'controlpersist no' "$batch"
    ! grep -q '^controlpath ' "$batch"

    sed "s/ localuser root$/ localuser $(id -un)/; s/ !localuser root$/ !localuser $(id -un)/" \
      "$TMPDIR/ssh_config" > "$TMPDIR/as-root"
    root="$TMPDIR/root"
    ssh -G -F "$TMPDIR/as-root" ${builder.hostName} > "$root"
    grep -qFx 'user ${builder.sshUser}' "$root"
    grep -qFx 'identityfile ${builder.sshKey}' "$root"
    test "$(grep -c '^identityfile ' "$root")" = 1
    grep -qFx 'userknownhostsfile /dev/null' "$root"
    grep -qFx 'batchmode yes' "$root"

    touch "$out"
  ''
