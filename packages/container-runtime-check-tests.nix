{
  containerRuntimeCheck,
  coreutils,
  runtimeShell,
  runCommand,
}:

runCommand "check-container-runtime-command"
  {
    nativeBuildInputs = [ coreutils ];
  }
  ''
    docker_double=$TMPDIR/docker-double
    port_check=$TMPDIR/port-check
    calls=$TMPDIR/docker.calls

    cat > "$docker_double" <<'EOF'
    #!${runtimeShell}
    set -eu
    printf '%s\n' "$*" >> "$DOUBLE_CALLS"

    if [ "$1 $2" = "context show" ]; then
      printf '%s\n' "''${ACTIVE_CONTEXT:-colima}"
      exit 0
    fi

    if [ "$1" = "info" ]; then
      if [ "''${ENGINE_TIMEOUT:-0}" -eq 1 ]; then
        sleep 3
      fi
      if [ "''${ENGINE_STOPPED:-0}" -eq 1 ]; then
        exit 1
      fi
      case "$*" in
        *--format*) printf '%s\n' 'linux|aarch64|colima' ;;
        *) printf '%s\n' 'diagnostic engine output' ;;
      esac
      exit 0
    fi

    case "$*" in
      *"run --rm --quiet --pull always --platform linux/arm64"*)
        printf '%s\n' aarch64
        ;;
      *"run --rm --quiet --pull always --platform linux/amd64"*)
        printf '%s\n' x86_64
        ;;
      *"volume inspect"*)
        last=
        for argument in "$@"; do
          last=$argument
        done
        case "$last" in
          *-sentinel-data) printf '%s\n' "$last" ;;
          *) exit 1 ;;
        esac
        ;;
      *"inspect --format {{.State.Health.Status}}"*)
        printf '%s\n' healthy
        ;;
      *"inspect --format {{.State.Running}}"*)
        printf '%s\n' true
        ;;
      *"ps -q sentinel"*)
        printf '%s\n' sentinel-container
        ;;
      *"ps -q db"*)
        printf '%s\n' db-container
        ;;
      *"port db 5432"*)
        printf '%s\n' 127.0.0.1:54321
        ;;
      *"exec -T db cat /exchange/input.txt"*)
        printf '%s\n' bind-ok
        ;;
      *"SELECT count(*) FROM persisted"*)
        printf '%s\n' 1
        ;;
      *"CREATE TABLE persisted"*)
        if [ "''${FAIL_DATABASE_WRITE:-0}" -eq 1 ]; then
          exit 23
        fi
        ;;
      *" cp db:/tmp/container-copy.txt "*)
        last=
        for argument in "$@"; do
          last=$argument
        done
        printf '%s' copy-ok > "$last"
        ;;
      *" logs --no-color"*)
        printf '%s\n' 'controlled diagnostic log'
        ;;
    esac
    EOF
    chmod +x "$docker_double"

    cat > "$port_check" <<'EOF'
    #!${runtimeShell}
    test "$1" = 54321
    EOF
    chmod +x "$port_check"

    run_failure() {
      name=$1
      shift
      root=$TMPDIR/$name
      mkdir -p "$root"
      : > "$calls"
      if env \
        DOUBLE_CALLS="$calls" \
        CONTAINER_RUNTIME_DOCKER="$docker_double" \
        CONTAINER_RUNTIME_PORT_CHECK="$port_check" \
        CONTAINER_RUNTIME_DIAGNOSTIC_DIR="$root" \
        "$@" \
        ${containerRuntimeCheck}/bin/container-runtime-check > "$root/output" 2>&1
      then
        echo "$name unexpectedly passed" >&2
        exit 1
      fi
    }

    run_failure redirected ACTIVE_CONTEXT=desktop-linux
    grep -qF "expected 'colima'" "$TMPDIR/redirected/output"
    grep -qF 'export DOCKER_CONTEXT=colima' "$TMPDIR/redirected/output"
    if grep -qF ' compose ' "$calls"; then
      echo 'redirected preflight started a Compose project' >&2
      exit 1
    fi

    run_failure stopped ENGINE_STOPPED=1
    grep -qF 'the Colima Docker engine is unavailable' "$TMPDIR/stopped/output"
    grep -qF 'colima start' "$TMPDIR/stopped/output"

    run_failure timeout ENGINE_TIMEOUT=1 CONTAINER_RUNTIME_COMMAND_TIMEOUT=1
    grep -qF 'Colima engine inspection' "$TMPDIR/timeout/output"
    grep -qF 'Diagnostics retained at' "$TMPDIR/timeout/output"

    success_root=$TMPDIR/success
    mkdir -p "$success_root"
    : > "$calls"
    env \
      DOUBLE_CALLS="$calls" \
      CONTAINER_RUNTIME_DOCKER="$docker_double" \
      CONTAINER_RUNTIME_PORT_CHECK="$port_check" \
      CONTAINER_RUNTIME_DIAGNOSTIC_DIR="$success_root" \
      ${containerRuntimeCheck}/bin/container-runtime-check > "$success_root/output" 2>&1
    grep -qF 'container-runtime-check: passed' "$success_root/output"
    grep -qF 'down --volumes --remove-orphans' "$calls"
    test "$(grep -cF 'down --volumes --remove-orphans' "$calls")" -eq 2
    set -- "$success_root"/container-runtime-check.*
    if [ -e "$1" ]; then
      echo 'successful acceptance retained its temporary directory' >&2
      exit 1
    fi

    : > "$calls"
    run_failure diagnostics FAIL_DATABASE_WRITE=1
    grep -qF 'database write failed' "$TMPDIR/diagnostics/output"
    grep -qF 'Diagnostics retained at' "$TMPDIR/diagnostics/output"
    grep -qF 'logs --no-color' "$calls"
    test "$(grep -cF 'down --volumes --remove-orphans' "$calls")" -eq 2
    test -f "$TMPDIR"/diagnostics/container-runtime-check.*/acceptance.log
    test -f "$TMPDIR"/diagnostics/container-runtime-check.*/sentinel.log

    touch $out
  ''
