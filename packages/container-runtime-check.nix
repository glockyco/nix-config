{
  colima,
  coreutils,
  docker-client,
  lib,
  python3,
  writeShellApplication,
}:

let
  images = {
    busybox = {
      reference = "docker.io/library/busybox@sha256:9db7b59979c38555a39def84a31fb98b5296952f9e3afd4f6f11f05b07adfab0";
      platforms = {
        "linux/arm64" = "aarch64";
        "linux/amd64" = "x86_64";
      };
    };
    postgres = {
      reference = "docker.io/library/postgres@sha256:00bc86618629af00d2937fdc5a5d63db3ff8450acf52f0636ec813c7f4902929";
      platforms = [
        "linux/arm64"
        "linux/amd64"
      ];
    };
  };

  package = writeShellApplication {
    name = "container-runtime-check";

    runtimeInputs = [
      colima
      coreutils
      docker-client
      python3
    ];

    text = ''
      docker_bin="''${CONTAINER_RUNTIME_DOCKER:-docker}"
      port_check_bin="''${CONTAINER_RUNTIME_PORT_CHECK:-${python3}/bin/python3}"
      command_timeout="''${CONTAINER_RUNTIME_COMMAND_TIMEOUT:-60}"
      pull_timeout="''${CONTAINER_RUNTIME_PULL_TIMEOUT:-300}"
      health_timeout="''${CONTAINER_RUNTIME_HEALTH_TIMEOUT:-120}"
      busybox_image=${lib.escapeShellArg images.busybox.reference}
      postgres_image=${lib.escapeShellArg images.postgres.reference}

      diagnostics_root="''${CONTAINER_RUNTIME_DIAGNOSTIC_DIR:-''${XDG_CACHE_HOME:-$HOME/.cache}/container-runtime-check}"
      mkdir -p "$diagnostics_root"
      work_dir="$(mktemp -d "$diagnostics_root/container-runtime-check.XXXXXX")"
      run_log="$work_dir/run.log"
      compose_file="$work_dir/compose.yaml"
      sentinel_file="$work_dir/sentinel.yaml"
      project="container-runtime-check-$$-$(date +%s)"
      sentinel_project="$project-sentinel"
      acceptance_volume="$project-data"
      sentinel_volume="$sentinel_project-data"
      acceptance_started=0
      sentinel_started=0
      failure_reported=0
      current_step="initialization"
      active_context=
      arm_arch=
      amd_arch=
      sentinel_container_before=
      sentinel_volume_before=
      db_container=
      health=
      published_endpoint=
      bind_content=
      persisted_rows=
      sentinel_container_after=
      sentinel_volume_after=
      sentinel_running=

      exec > >(tee -a "$run_log") 2>&1

      recovery_command() {
        printf '%s\n' "Recovery: colima start"
        printf '%s\n' "Recovery: export DOCKER_CONTEXT=colima"
        printf '%s\n' "Recovery: docker compose -p $project -f $compose_file down --volumes --remove-orphans"
        printf '%s\n' "Recovery: docker compose -p $sentinel_project -f $sentinel_file down --volumes --remove-orphans"
      }

      fail() {
        failure_reported=1
        printf 'container-runtime-check: %s\n' "$1" >&2
        recovery_command >&2
        exit 1
      }

      step() {
        local label=$1
        local limit=$2
        shift 2
        current_step=$label
        if ! timeout --foreground "$limit" "$@"; then
          fail "$label failed or exceeded $limit seconds"
        fi
      }

      capture() {
        local label=$1
        local limit=$2
        local destination=$3
        local output
        local status
        shift 3
        current_step=$label
        set +e
        output="$(timeout --foreground "$limit" "$@" 2>&1)"
        status=$?
        set -e
        printf '%s\n' "$output" >> "$run_log"
        if [ "$status" -ne 0 ]; then
          fail "$label failed or exceeded $limit seconds"
        fi
        printf -v "$destination" '%s' "$output"
      }

      cleanup_project() {
        local name=$1
        local file=$2
        timeout --foreground "$command_timeout" "$docker_bin" compose \
          -p "$name" -f "$file" down --volumes --remove-orphans >/dev/null 2>&1 || true
      }

      collect_diagnostics() {
        timeout --foreground "$command_timeout" "$docker_bin" info > "$work_dir/docker-info.log" 2>&1 || true
        if [ "$acceptance_started" -eq 1 ]; then
          timeout --foreground "$command_timeout" "$docker_bin" compose \
            -p "$project" -f "$compose_file" logs --no-color > "$work_dir/acceptance.log" 2>&1 || true
        fi
        if [ "$sentinel_started" -eq 1 ]; then
          timeout --foreground "$command_timeout" "$docker_bin" compose \
            -p "$sentinel_project" -f "$sentinel_file" logs --no-color > "$work_dir/sentinel.log" 2>&1 || true
        fi
      }

      on_exit() {
        local status=$?
        trap - EXIT INT TERM
        set +e

        if [ "$status" -ne 0 ]; then
          collect_diagnostics
        fi
        if [ "$acceptance_started" -eq 1 ]; then
          cleanup_project "$project" "$compose_file"
        fi
        if [ "$sentinel_started" -eq 1 ]; then
          cleanup_project "$sentinel_project" "$sentinel_file"
        fi

        if [ "$status" -eq 0 ]; then
          rm -rf "$work_dir"
          printf '%s\n' "container-runtime-check: passed"
        else
          if [ "$failure_reported" -eq 0 ]; then
            printf 'container-runtime-check: %s failed\n' "$current_step" >&2
            recovery_command >&2
          fi
          printf 'Diagnostics retained at %s\n' "$work_dir" >&2
        fi
        exit "$status"
      }

      trap on_exit EXIT
      trap 'current_step="interrupted"; exit 130' INT TERM

      capture "Docker context inspection" "$command_timeout" active_context \
        "$docker_bin" context show
      if [ "$active_context" != "colima" ]; then
        fail "active Docker context is '$active_context', expected 'colima'. Run: export DOCKER_CONTEXT=colima"
      fi

      current_step="Colima engine inspection"
      set +e
      engine_identity="$(timeout --foreground "$command_timeout" "$docker_bin" info \
        --format '{{.OSType}}|{{.Architecture}}|{{.Name}}' 2>&1)"
      engine_status=$?
      set -e
      printf '%s\n' "$engine_identity" >> "$run_log"
      if [ "$engine_status" -eq 124 ]; then
        fail "Colima engine inspection exceeded $command_timeout seconds"
      elif [ "$engine_status" -ne 0 ]; then
        fail "the Colima Docker engine is unavailable. Run: colima start"
      fi
      case "$engine_identity" in
        "linux|aarch64|colima"|"linux|arm64|colima") ;;
        *) fail "unexpected Docker engine identity '$engine_identity'" ;;
      esac

      capture "ARM64 smoke execution" "$pull_timeout" arm_arch \
        "$docker_bin" run --rm --quiet --pull always --platform linux/arm64 "$busybox_image" uname -m
      if [ "$arm_arch" != "aarch64" ]; then
        fail "ARM64 smoke container reported '$arm_arch'"
      fi

      capture "AMD64 smoke execution" "$pull_timeout" amd_arch \
        "$docker_bin" run --rm --quiet --pull always --platform linux/amd64 "$busybox_image" uname -m
      if [ "$amd_arch" != "x86_64" ]; then
        fail "AMD64 smoke container reported '$amd_arch'"
      fi

      mkdir -p "$work_dir/bind" "$work_dir/job"
      printf '%s\n' 'bind-ok' > "$work_dir/bind/input.txt"
      cat > "$work_dir/job/Dockerfile" <<EOF
      FROM $busybox_image
      CMD ["true"]
      EOF

      cat > "$compose_file" <<EOF
      services:
        db:
          image: $postgres_image
          environment:
            POSTGRES_DB: acceptance
            POSTGRES_PASSWORD: acceptance
          healthcheck:
            test: ["CMD-SHELL", "pg_isready -U postgres -d acceptance"]
            interval: 2s
            timeout: 2s
            retries: 30
          ports:
            - "127.0.0.1::5432"
          volumes:
            - data:/var/lib/postgresql/data
            - "$work_dir/bind:/exchange"
        job:
          build:
            context: ./job
      volumes:
        data:
          name: $acceptance_volume
      EOF

      cat > "$sentinel_file" <<EOF
      services:
        sentinel:
          image: $busybox_image
          command: ["sleep", "600"]
          volumes:
            - sentinel-data:/sentinel
      volumes:
        sentinel-data:
          name: $sentinel_volume
      EOF

      sentinel_started=1
      step "sentinel project startup" "$pull_timeout" "$docker_bin" compose \
        -p "$sentinel_project" -f "$sentinel_file" up -d
      capture "sentinel container identity" "$command_timeout" sentinel_container_before \
        "$docker_bin" compose -p "$sentinel_project" -f "$sentinel_file" ps -q sentinel
      capture "sentinel volume identity" "$command_timeout" sentinel_volume_before \
        "$docker_bin" volume inspect --format '{{.Name}}' "$sentinel_volume"

      acceptance_started=1
      step "Compose service startup" "$pull_timeout" "$docker_bin" compose \
        -p "$project" -f "$compose_file" up -d --wait --wait-timeout "$health_timeout" db
      capture "database container identity" "$command_timeout" db_container \
        "$docker_bin" compose -p "$project" -f "$compose_file" ps -q db
      capture "database health inspection" "$command_timeout" health \
        "$docker_bin" inspect --format '{{.State.Health.Status}}' "$db_container"
      if [ "$health" != "healthy" ]; then
        fail "PostgreSQL service reported health '$health'"
      fi

      capture "published port inspection" "$command_timeout" published_endpoint \
        "$docker_bin" compose -p "$project" -f "$compose_file" port db 5432
      published_port="''${published_endpoint##*:}"
      current_step="published loopback connection"
      if [ "$port_check_bin" = "${python3}/bin/python3" ]; then
        step "$current_step" "$command_timeout" "$port_check_bin" -c \
          'import socket, sys; s = socket.create_connection(("127.0.0.1", int(sys.argv[1])), timeout=5); s.close()' \
          "$published_port"
      else
        step "$current_step" "$command_timeout" "$port_check_bin" "$published_port"
      fi

      capture "bind mount verification" "$command_timeout" bind_content \
        "$docker_bin" compose -p "$project" -f "$compose_file" exec -T db \
        cat /exchange/input.txt
      if [ "$bind_content" != "bind-ok" ]; then
        fail "bind mount returned unexpected content"
      fi
      step "database write" "$command_timeout" "$docker_bin" compose \
        -p "$project" -f "$compose_file" exec -T db psql -U postgres -d acceptance -v ON_ERROR_STOP=1 \
        -c 'CREATE TABLE persisted(value integer); INSERT INTO persisted VALUES (1);'
      step "database restart" "$command_timeout" "$docker_bin" compose \
        -p "$project" -f "$compose_file" restart db
      step "database readiness after restart" "$health_timeout" "$docker_bin" compose \
        -p "$project" -f "$compose_file" up -d --wait --wait-timeout "$health_timeout" db
      capture "named volume persistence" "$command_timeout" persisted_rows \
        "$docker_bin" compose -p "$project" -f "$compose_file" exec -T db \
        psql -U postgres -d acceptance -Atc 'SELECT count(*) FROM persisted;'
      if [ "$persisted_rows" != "1" ]; then
        fail "named volume did not preserve the database row"
      fi

      step "container copy source creation" "$command_timeout" "$docker_bin" compose \
        -p "$project" -f "$compose_file" exec -T db sh -c 'printf copy-ok > /tmp/container-copy.txt'
      step "Compose file copy" "$command_timeout" "$docker_bin" compose \
        -p "$project" -f "$compose_file" cp db:/tmp/container-copy.txt "$work_dir/copied.txt"
      if [ "$(cat "$work_dir/copied.txt")" != "copy-ok" ]; then
        fail "docker compose cp returned unexpected content"
      fi

      step "Compose image build" "$pull_timeout" "$docker_bin" compose \
        -p "$project" -f "$compose_file" build job
      step "one-shot Compose execution" "$command_timeout" "$docker_bin" compose \
        -p "$project" -f "$compose_file" run --rm job

      step "acceptance project cleanup" "$command_timeout" "$docker_bin" compose \
        -p "$project" -f "$compose_file" down --volumes --remove-orphans
      acceptance_started=0

      current_step="acceptance volume removal"
      if timeout --foreground "$command_timeout" "$docker_bin" volume inspect "$acceptance_volume" >/dev/null 2>&1; then
        fail "acceptance volume '$acceptance_volume' still exists after cleanup"
      fi

      capture "sentinel container reinspection" "$command_timeout" sentinel_container_after \
        "$docker_bin" compose -p "$sentinel_project" -f "$sentinel_file" ps -q sentinel
      capture "sentinel volume reinspection" "$command_timeout" sentinel_volume_after \
        "$docker_bin" volume inspect --format '{{.Name}}' "$sentinel_volume"
      capture "sentinel running state" "$command_timeout" sentinel_running \
        "$docker_bin" inspect --format '{{.State.Running}}' "$sentinel_container_after"

      if [ -z "$sentinel_container_before" ] || [ "$sentinel_container_before" != "$sentinel_container_after" ]; then
        fail "sentinel container changed during acceptance cleanup"
      fi
      if [ "$sentinel_volume_before" != "$sentinel_volume_after" ]; then
        fail "sentinel volume changed during acceptance cleanup"
      fi
      if [ "$sentinel_running" != "true" ]; then
        fail "sentinel container stopped during acceptance cleanup"
      fi
    '';
  };
in
package.overrideAttrs (old: {
  passthru = (old.passthru or { }) // {
    inherit images;
  };
})
