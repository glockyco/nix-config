{
  coreutils,
  gnugrep,
  gnused,
  openssh,
  runCommand,
  # The rendered system client configuration.
  sshConfig,
  # The declared remote build machine; user endpoints are checked from chezmoi.
  builder,
}:

# Root and the Nix daemon use the system's root-only credential. User aliases
# live solely in chezmoi and are exercised by the rendered user SSH check.
# The sandbox cannot run as root, so matching its build user proves that branch.
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

    # The system declaration must never give an ordinary user the builder key.
    ssh -G -F "$TMPDIR/ssh_config" ${builder.hostName} > "$TMPDIR/user"
    ! grep -qFx 'identityfile ${builder.sshKey}' "$TMPDIR/user"

    sed "s/ localuser root$/ localuser $(id -un)/; s/ !localuser root$/ !localuser $(id -un)/" \
      "$TMPDIR/ssh_config" > "$TMPDIR/as-root"
    root="$TMPDIR/root"
    ssh -G -F "$TMPDIR/as-root" ${builder.hostName} > "$root"
    grep -qFx 'user ${builder.sshUser}' "$root"
    grep -qFx 'identityfile ${builder.sshKey}' "$root"
    test "$(grep -c '^identityfile ' "$root")" = 1
    grep -qFx 'userknownhostsfile /dev/null' "$root"
    grep -qFx 'batchmode yes' "$root"
    grep -qFx 'identitiesonly yes' "$root"
    grep -qFx 'stricthostkeychecking true' "$root"
    grep -qFx 'controlmaster false' "$root"
    grep -qFx 'connecttimeout 8' "$root"

    touch "$out"
  ''
