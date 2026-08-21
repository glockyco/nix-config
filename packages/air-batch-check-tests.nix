{
  airBatchCheck,
  coreutils,
  runtimeShell,
  runCommand,
}:

runCommand "check-air-batch-command"
  {
    nativeBuildInputs = [ coreutils ];
  }
  ''
    ssh_double=$TMPDIR/ssh-double
    rsync_double=$TMPDIR/rsync-double
    calls=$TMPDIR/ssh.calls

    cat > "$ssh_double" <<'EOF'
    #!${runtimeShell}
    set -eu
    printf '%s\n' "$*" >> "$SSH_CALLS"

    case "$*" in
      "-G test-air-batch")
        cat <<'POLICY'
    user joaichberger
    hostname macbook-air-von-isys.local
    batchmode yes
    controlmaster false
    requesttty false
    stdinnull no
    connecttimeout 8
    controlpersist no
    POLICY
        ;;
      "-n test-air-batch true")
        if [ "''${SSH_TIMEOUT:-0}" -eq 1 ]; then
          sleep 3
        fi
        if [ "''${AUTH_FAILURE:-0}" -eq 1 ]; then
          exit 255
        fi
        if [ "''${REMOTE_COMMAND_FAILURE:-0}" -eq 1 ]; then
          exit 17
        fi
        ;;
      "-n test-air-batch exit 23")
        if [ "''${BAD_FAILURE_STATUS:-0}" -eq 1 ]; then
          exit 24
        fi
        exit 23
        ;;
      "-n test-air-batch test -x /usr/local/bin/docker")
        if [ "''${REMOTE_DOCKER_MISSING:-0}" -eq 1 ]; then
          exit 1
        fi
        ;;
      "-n test-air-batch /usr/local/bin/docker info")
        printf '%s\n' ' OSType: linux'
        ;;
      "-O check test-air-batch")
        exit 255
        ;;
      *)
        printf '%s\n' "unexpected ssh call: $*" >&2
        exit 99
        ;;
    esac
    EOF
    chmod +x "$ssh_double"

    cat > "$rsync_double" <<'EOF'
    #!${runtimeShell}
    set -eu
    printf '%s\n' "$*" >> "$RSYNC_CALLS"
    if [ "''${TRANSFER_FAILURE:-0}" -eq 1 ]; then
      exit 12
    fi
    destination=
    for argument in "$@"; do
      destination=$argument
    done
    printf '%s\n' '127.0.0.1 localhost' > "$destination"
    EOF
    chmod +x "$rsync_double"

    run_check() {
      root=$1
      shift
      mkdir -p "$root"
      : > "$calls"
      : > "$root/rsync.calls"
      env \
        SSH_CALLS="$calls" \
        RSYNC_CALLS="$root/rsync.calls" \
        AIR_BATCH_SSH="$ssh_double" \
        AIR_BATCH_RSYNC="$rsync_double" \
        AIR_BATCH_HOST=test-air-batch \
        AIR_BATCH_DIAGNOSTIC_DIR="$root" \
        AIR_BATCH_DOCKER=/usr/local/bin/docker \
        "$@" \
        ${airBatchCheck}/bin/air-batch-check > "$root/output" 2>&1
    }

    assert_clean() {
      root=$1
      set -- "$root"/air-batch-check.*
      if [ -e "$1" ]; then
        echo "acceptance retained temporary state under $root" >&2
        exit 1
      fi
    }

    run_failure() {
      name=$1
      shift
      root=$TMPDIR/$name
      if run_check "$root" "$@"; then
        echo "$name unexpectedly passed" >&2
        exit 1
      fi
      assert_clean "$root"
      grep -qF 'Recovery: confirm the Air is reachable' "$root/output"
    }

    success=$TMPDIR/success
    run_check "$success"
    grep -qF 'air-batch-check: passed' "$success/output"
    grep -qF -- '-n test-air-batch true' "$calls"
    grep -qF -- '-n test-air-batch exit 23' "$calls"
    grep -qF -- '-n test-air-batch test -x /usr/local/bin/docker' "$calls"
    grep -qF -- '-n test-air-batch /usr/local/bin/docker info' "$calls"
    grep -qF -- '-O check test-air-batch' "$calls"
    grep -qF -- '--archive -- test-air-batch:/etc/hosts' "$success/rsync.calls"
    assert_clean "$success"

    run_failure timeout SSH_TIMEOUT=1 AIR_BATCH_COMMAND_TIMEOUT=1
    grep -qF 'detached-stdin command exceeded 1 seconds' "$TMPDIR/timeout/output"

    run_failure authentication AUTH_FAILURE=1
    grep -qF 'detached-stdin command returned status 255, expected 0' "$TMPDIR/authentication/output"

    run_failure remote-command REMOTE_COMMAND_FAILURE=1
    grep -qF 'detached-stdin command returned status 17, expected 0' "$TMPDIR/remote-command/output"

    run_failure failure-status BAD_FAILURE_STATUS=1
    grep -qF 'remote failure propagation returned status 24, expected 23' "$TMPDIR/failure-status/output"

    run_failure transfer TRANSFER_FAILURE=1
    grep -qF 'read-only transfer returned status 12, expected 0' "$TMPDIR/transfer/output"

    run_failure remote-docker REMOTE_DOCKER_MISSING=1
    grep -qF 'remote Docker path returned status 1, expected 0' "$TMPDIR/remote-docker/output"

    missing=$TMPDIR/missing-docker
    mkdir -p "$missing"
    : > "$calls"
    if env \
      SSH_CALLS="$calls" \
      RSYNC_CALLS="$missing/rsync.calls" \
      AIR_BATCH_SSH="$ssh_double" \
      AIR_BATCH_RSYNC="$rsync_double" \
      AIR_BATCH_HOST=test-air-batch \
      AIR_BATCH_DIAGNOSTIC_DIR="$missing" \
      AIR_BATCH_DOCKER= \
      ${airBatchCheck}/bin/air-batch-check > "$missing/output" 2>&1
    then
      echo 'missing Docker executable unexpectedly passed' >&2
      exit 1
    fi
    grep -qF 'AIR_BATCH_DOCKER is required' "$missing/output"
    test ! -s "$calls"
    assert_clean "$missing"

    touch $out
  ''
