{
  coreutils,
  gnugrep,
  openssh,
  rsync,
  writeShellApplication,
}:

writeShellApplication {
  name = "air-batch-check";

  runtimeInputs = [
    coreutils
    gnugrep
    openssh
    rsync
  ];

  text = ''
    ssh_bin="''${AIR_BATCH_SSH:-ssh}"
    rsync_bin="''${AIR_BATCH_RSYNC:-rsync}"
    timeout_bin="''${AIR_BATCH_TIMEOUT:-timeout}"
    host="''${AIR_BATCH_HOST:-air-batch}"
    command_timeout="''${AIR_BATCH_COMMAND_TIMEOUT:-15}"
    remote_docker="''${AIR_BATCH_DOCKER:-}"
    diagnostics_root="''${AIR_BATCH_DIAGNOSTIC_DIR:-''${XDG_CACHE_HOME:-$HOME/.cache}/air-batch-check}"

    mkdir -p "$diagnostics_root"
    work_dir=$(mktemp -d "$diagnostics_root/air-batch-check.XXXXXX")

    cleanup() {
      rm -rf "$work_dir"
    }
    trap cleanup EXIT
    trap 'exit 1' HUP INT TERM

    recover() {
      printf '%s\n' "Recovery: confirm the Air is reachable with: ssh -n $host true" >&2
      printf '%s\n' "Recovery: inspect the resolved policy with: ssh -G $host" >&2
      printf '%s\n' 'Recovery: verify AIR_BATCH_DOCKER names an absolute executable on the Air' >&2
    }

    fail() {
      printf '%s\n' "air-batch-check: $1" >&2
      recover
      exit 1
    }

    case "$command_timeout" in
      *[!0-9]* | 0) fail "AIR_BATCH_COMMAND_TIMEOUT must be a positive integer" ;;
    esac

    if [ -z "$remote_docker" ]; then
      fail "AIR_BATCH_DOCKER is required"
    fi
    case "$remote_docker" in
      /*) ;;
      *) fail "AIR_BATCH_DOCKER must be an absolute remote path" ;;
    esac

    run_probe() {
      label=$1
      expected_status=$2
      output=$3
      shift 3
      started=$(date +%s)
      set +e
      "$timeout_bin" --foreground "$command_timeout" "$@" > "$output" 2>&1
      status=$?
      set -e
      elapsed=$(( $(date +%s) - started ))

      if [ "$status" -eq 124 ]; then
        cat "$output" >&2
        fail "$label exceeded $command_timeout seconds"
      fi
      if [ "$status" -ne "$expected_status" ]; then
        cat "$output" >&2
        fail "$label returned status $status, expected $expected_status"
      fi
      printf '%s\n' "air-batch-check: $label passed (''${elapsed}s)"
    }

    run_probe \
      "resolved policy" 0 "$work_dir/policy.log" \
      "$ssh_bin" -G "$host"
    grep -qFx 'batchmode yes' "$work_dir/policy.log" || fail "resolved policy permits prompts"
    grep -qFx 'controlmaster false' "$work_dir/policy.log" || fail "resolved policy permits a control master"
    grep -qFx 'controlpersist no' "$work_dir/policy.log" || fail "resolved policy permits connection persistence"
    grep -qFx 'requesttty false' "$work_dir/policy.log" || fail "resolved policy permits a terminal"
    grep -qFx 'stdinnull no' "$work_dir/policy.log" || fail "resolved policy disables protocol streams"
    if grep -q '^controlpath ' "$work_dir/policy.log"; then
      fail "resolved policy declares a control socket"
    fi

    run_probe \
      "detached-stdin command" 0 "$work_dir/command.log" \
      "$ssh_bin" -n "$host" true

    run_probe \
      "remote failure propagation" 23 "$work_dir/failure.log" \
      "$ssh_bin" -n "$host" 'exit 23'

    run_probe \
      "read-only transfer" 0 "$work_dir/rsync.log" \
      "$rsync_bin" --archive -- "$host:/etc/hosts" "$work_dir/air-hosts"
    test -s "$work_dir/air-hosts" || fail "read-only transfer returned no data"

    run_probe \
      "remote Docker path" 0 "$work_dir/docker-path.log" \
      "$ssh_bin" -n "$host" test -x "$remote_docker"

    run_probe \
      "read-only Docker inspection" 0 "$work_dir/docker.log" \
      "$ssh_bin" -n "$host" "$remote_docker" info
    grep -Eq '^[[:space:]]*OSType:[[:space:]]*linux$' "$work_dir/docker.log" || fail "remote Docker inspection did not report a Linux engine"

    run_probe \
      "persistent master absence" 255 "$work_dir/master.log" \
      "$ssh_bin" -O check "$host"

    printf '%s\n' 'air-batch-check: passed'
  '';
}
