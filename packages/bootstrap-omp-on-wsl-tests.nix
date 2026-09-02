{
  bootstrapOmpOnWsl,
  coreutils,
  git,
  jq,
  runtimeShell,
  runCommand,
}:

runCommand "check-bootstrap-omp-on-wsl-command"
  {
    nativeBuildInputs = [
      coreutils
      git
      jq
    ];
  }
  ''
    nix_double=$TMPDIR/nix-double
    cat > "$nix_double" <<'EOF'
    #!${runtimeShell}
    set -eu
    printf '%s\n' "$*" >> "$BOOTSTRAP_NIX_CALLS"

    profile=
    previous=
    for argument in "$@"; do
      if [ "$previous" = --profile ]; then
        profile=$argument
      fi
      previous=$argument
    done

    if [ "$1 $2" = "profile list" ]; then
      if [ -f "$BOOTSTRAP_PROFILE_STATE" ]; then
        cat "$BOOTSTRAP_PROFILE_STATE"
      else
        printf '%s\n' '{"elements":{}}'
      fi
      exit 0
    fi

    if [ "$1 $2" = "profile remove" ]; then
      entry=
      for argument in "$@"; do
        entry=$argument
      done
      jq --arg entry "$entry" 'del(.elements[$entry])' \
        "$BOOTSTRAP_PROFILE_STATE" > "$BOOTSTRAP_PROFILE_STATE.next"
      mv "$BOOTSTRAP_PROFILE_STATE.next" "$BOOTSTRAP_PROFILE_STATE"
      exit 0
    fi

    if [ "$1 $2" = "profile add" ]; then
      environment=
      for argument in "$@"; do
        environment=$argument
      done
      if [ -f "$BOOTSTRAP_PROFILE_STATE" ]; then
        jq --arg environment "$environment" \
          '.elements["personal-omp-wsl"] = {"storePaths":[$environment]}' \
          "$BOOTSTRAP_PROFILE_STATE" > "$BOOTSTRAP_PROFILE_STATE.next"
      else
        jq -n --arg environment "$environment" \
          '{"version":3,"elements":{"personal-omp-wsl":{"storePaths":[$environment]}}}' \
          > "$BOOTSTRAP_PROFILE_STATE.next"
      fi
      mv "$BOOTSTRAP_PROFILE_STATE.next" "$BOOTSTRAP_PROFILE_STATE"
      generation="''${BOOTSTRAP_NEW_GENERATION:-1}"
      generation_dir="$(dirname "$profile")/generation-$generation"
      mkdir -p "$generation_dir/bin"
      for command in "$environment"/bin/*; do
        ln -s "$command" "$generation_dir/bin/$(basename "$command")"
      done
      ln -sfn "generation-$generation" "$(dirname "$profile")/profile-$generation-link"
      ln -sfn "profile-$generation-link" "$profile"
      exit 0
    fi

    if [ "$1 $2" = "profile rollback" ]; then
      generation=
      previous=
      for argument in "$@"; do
        if [ "$previous" = --to ]; then
          generation=$argument
        fi
        previous=$argument
      done
      cp "$BOOTSTRAP_PREVIOUS_STATE" "$BOOTSTRAP_PROFILE_STATE"
      ln -sfn "profile-$generation-link" "$profile"
      exit 0
    fi

    printf 'unexpected nix invocation: %s\n' "$*" >&2
    exit 64
    EOF
    chmod +x "$nix_double"

    make_repo() {
      root=$1
      mkdir -p "$root"
      ${git}/bin/git -C "$root" init --quiet --initial-branch=main
      ${git}/bin/git -C "$root" config user.email johann.glock@scch.at
      printf '%s\n' '{ }' > "$root/flake.nix"
      printf '%s\n' '{ }' > "$root/flake.lock"
    }

    make_environment() {
      root=$1
      label=$2
      mkdir -p "$root/bin"
      for command in omp openspec; do
        cat > "$root/bin/$command" <<EOF
    #!${runtimeShell}
    exit 0
    EOF
        chmod +x "$root/bin/$command"
      done
      cat > "$root/bin/reconcile-herdr-omp" <<EOF
    #!${runtimeShell}
    set -eu
    printf '%s\n' '$label-reconcile' >> "\$BOOTSTRAP_HELPER_CALLS"
    mkdir -p "\$HOME/.omp/agent/extensions"
    touch "\$HOME/.omp/agent/extensions/herdr-omp-agent-state.ts"
    if [ "\''${BOOTSTRAP_FAIL_RECONCILIATION:-0}" -eq 1 ] && [ '$label' = new ]; then
      exit 21
    fi
    EOF
      cat > "$root/bin/verify-personal-omp" <<EOF
    #!${runtimeShell}
    set -eu
    printf '%s\n' '$label-verify' >> "\$BOOTSTRAP_HELPER_CALLS"
    if [ "\''${BOOTSTRAP_FAIL_VERIFICATION:-0}" -eq 1 ] && [ '$label' = new ]; then
      exit 22
    fi
    printf '%s\n' 'OMP: test' 'Plugin: /nix/store/test-plugin' 'omp: current (v8)'
    EOF
      chmod +x "$root/bin/reconcile-herdr-omp" "$root/bin/verify-personal-omp"
    }

    run_bootstrap() {
      repo=$1
      shift
      env \
        HOME="$BOOTSTRAP_HOME" \
        BOOTSTRAP_NIX_BIN="$nix_double" \
        BOOTSTRAP_ENVIRONMENT="$BOOTSTRAP_NEW_ENVIRONMENT" \
        BOOTSTRAP_PROFILE="$BOOTSTRAP_TEST_PROFILE" \
        BOOTSTRAP_PROFILE_STATE="$BOOTSTRAP_STATE" \
        BOOTSTRAP_PREVIOUS_STATE="$BOOTSTRAP_OLD_STATE" \
        BOOTSTRAP_NIX_CALLS="$BOOTSTRAP_CALLS" \
        BOOTSTRAP_HELPER_CALLS="$BOOTSTRAP_HELPERS" \
        BOOTSTRAP_KERNEL_NAME=Linux \
        BOOTSTRAP_KERNEL_RELEASE=6.18.33.2-microsoft-standard-WSL2 \
        BOOTSTRAP_MACHINE=x86_64 \
        "$@" \
        ${bootstrapOmpOnWsl}/bin/bootstrap-omp-on-wsl
    }

    expect_failure() {
      name=$1
      shift
      if "$@" > "$TMPDIR/$name.output" 2>&1; then
        printf '%s unexpectedly passed\n' "$name" >&2
        exit 1
      fi
    }

    platform_repo=$TMPDIR/platform-repo
    make_repo "$platform_repo"
    export BOOTSTRAP_HOME=$TMPDIR/platform-home
    export BOOTSTRAP_TEST_PROFILE=$TMPDIR/platform-profile/profile
    export BOOTSTRAP_NEW_ENVIRONMENT=$TMPDIR/platform-environment
    export BOOTSTRAP_STATE=$TMPDIR/platform-state.json
    export BOOTSTRAP_OLD_STATE=$TMPDIR/platform-old-state.json
    export BOOTSTRAP_CALLS=$TMPDIR/platform.calls
    export BOOTSTRAP_HELPERS=$TMPDIR/platform.helpers
    mkdir -p "$BOOTSTRAP_HOME"
    make_environment "$BOOTSTRAP_NEW_ENVIRONMENT" new
    : > "$BOOTSTRAP_CALLS"
    : > "$BOOTSTRAP_HELPERS"

    (
      cd "$platform_repo"
      expect_failure native run_bootstrap "$platform_repo" BOOTSTRAP_KERNEL_RELEASE=6.18.0-generic
    )
    grep -qF 'WSL 2 is required' "$TMPDIR/native.output"
    test ! -s "$BOOTSTRAP_CALLS"

    (
      cd "$platform_repo"
      expect_failure wsl1 run_bootstrap "$platform_repo" BOOTSTRAP_KERNEL_RELEASE=4.4.0-Microsoft
    )
    grep -qF 'WSL 2 is required' "$TMPDIR/wsl1.output"
    test ! -s "$BOOTSTRAP_CALLS"

    (
      cd "$platform_repo"
      expect_failure architecture run_bootstrap "$platform_repo" BOOTSTRAP_MACHINE=aarch64
    )
    grep -qF 'unsupported architecture: aarch64' "$TMPDIR/architecture.output"
    test ! -s "$BOOTSTRAP_CALLS"

    non_repo=$TMPDIR/non-repo
    mkdir -p "$non_repo"
    (
      cd "$non_repo"
      expect_failure non-worktree run_bootstrap "$non_repo"
    )
    grep -qF 'run this command from the nix-config Git worktree root' "$TMPDIR/non-worktree.output"
    test ! -s "$BOOTSTRAP_CALLS"

    clean=$TMPDIR/clean
    make_repo "$clean/repo"
    export BOOTSTRAP_HOME=$clean/home
    export BOOTSTRAP_TEST_PROFILE=$clean/profiles/profile
    export BOOTSTRAP_NEW_ENVIRONMENT=$clean/new-personal-omp-wsl
    export BOOTSTRAP_STATE=$clean/state.json
    export BOOTSTRAP_OLD_STATE=$clean/old-state.json
    export BOOTSTRAP_CALLS=$clean/nix.calls
    export BOOTSTRAP_HELPERS=$clean/helper.calls
    mkdir -p "$BOOTSTRAP_HOME/.omp/agent"
    HOME="$BOOTSTRAP_HOME" ${git}/bin/git config --global user.email johann.glock@scch.at
    printf '%s\n' config-sentinel > "$BOOTSTRAP_HOME/.omp/agent/config.yml"
    printf '%s\n' database-sentinel > "$BOOTSTRAP_HOME/.omp/agent/agent.db"
    make_environment "$BOOTSTRAP_NEW_ENVIRONMENT" new
    : > "$BOOTSTRAP_CALLS"
    : > "$BOOTSTRAP_HELPERS"
    clean_status_before="$(${git}/bin/git -C "$clean/repo" status --porcelain=v2 --untracked-files=all)"
    clean_lock_before="$(sha256sum "$clean/repo/flake.lock")"

    (
      cd "$clean/repo"
      run_bootstrap "$clean/repo" > "$clean/output"
    )
    grep -qF 'bootstrap-omp-on-wsl: ready' "$clean/output"
    test "$(${git}/bin/git -C "$clean/repo" config --local user.email)" = 11704293+glockyco@users.noreply.github.com
    test "$(HOME="$BOOTSTRAP_HOME" ${git}/bin/git config --global user.email)" = johann.glock@scch.at
    test "$(cat "$BOOTSTRAP_HOME/.omp/agent/config.yml")" = config-sentinel
    test "$(cat "$BOOTSTRAP_HOME/.omp/agent/agent.db")" = database-sentinel
    test "$(${git}/bin/git -C "$clean/repo" status --porcelain=v2 --untracked-files=all)" = "$clean_status_before"
    test "$(sha256sum "$clean/repo/flake.lock")" = "$clean_lock_before"
    test "$(grep -cF 'profile add' "$BOOTSTRAP_CALLS")" -eq 1
    test "$(cat "$BOOTSTRAP_HELPERS")" = "new-reconcile
    new-verify"

    clean_generation="$(readlink "$BOOTSTRAP_TEST_PROFILE")"
    (
      cd "$clean/repo"
      run_bootstrap "$clean/repo" > "$clean/reentry.output"
    )
    test "$(readlink "$BOOTSTRAP_TEST_PROFILE")" = "$clean_generation"
    test "$(grep -cF 'profile add' "$BOOTSTRAP_CALLS")" -eq 1
    test "$(jq '.elements | length' "$BOOTSTRAP_STATE")" -eq 1

    replacement=$TMPDIR/replacement
    make_repo "$replacement/repo"
    export BOOTSTRAP_HOME=$replacement/home
    export BOOTSTRAP_TEST_PROFILE=$replacement/profiles/profile
    export BOOTSTRAP_NEW_ENVIRONMENT=$replacement/new-personal-omp-wsl
    export BOOTSTRAP_STATE=$replacement/state.json
    export BOOTSTRAP_OLD_STATE=$replacement/old-state.json
    export BOOTSTRAP_CALLS=$replacement/nix.calls
    export BOOTSTRAP_HELPERS=$replacement/helper.calls
    export BOOTSTRAP_NEW_GENERATION=2
    mkdir -p "$BOOTSTRAP_HOME" "$replacement/profiles/generation-1/bin"
    make_environment "$replacement/old-personal-omp-wsl" old
    make_environment "$BOOTSTRAP_NEW_ENVIRONMENT" new
    for command in "$replacement/old-personal-omp-wsl"/bin/*; do
      ln -s "$command" "$replacement/profiles/generation-1/bin/$(basename "$command")"
    done
    ln -s generation-1 "$replacement/profiles/profile-1-link"
    ln -s profile-1-link "$BOOTSTRAP_TEST_PROFILE"
    jq -n \
      --arg old "$replacement/old-personal-omp-wsl" \
      --arg legacy_personal_omp ${bootstrapOmpOnWsl.environment.personalOmp} \
      --arg legacy_openspec ${bootstrapOmpOnWsl.environment.openspec} \
      '{"version":3,"elements":{"personal-omp-wsl":{"storePaths":[$old]},"personal-omp":{"storePaths":[$legacy_personal_omp]},"openspec":{"storePaths":[$legacy_openspec]},"unrelated":{"storePaths":["/nix/store/unrelated"]}}}' \
      > "$BOOTSTRAP_STATE"
    cp "$BOOTSTRAP_STATE" "$BOOTSTRAP_OLD_STATE"
    : > "$BOOTSTRAP_CALLS"
    : > "$BOOTSTRAP_HELPERS"

    (
      cd "$replacement/repo"
      run_bootstrap "$replacement/repo" > "$replacement/output"
    )
    test "$(jq -r '.elements.unrelated.storePaths[0]' "$BOOTSTRAP_STATE")" = /nix/store/unrelated
    test "$(jq -r '.elements."personal-omp-wsl".storePaths[0]' "$BOOTSTRAP_STATE")" = "$BOOTSTRAP_NEW_ENVIRONMENT"
    test "$(jq '.elements | length' "$BOOTSTRAP_STATE")" -eq 2
    test "$(grep -cF 'profile remove' "$BOOTSTRAP_CALLS")" -eq 3
    test "$(readlink "$BOOTSTRAP_TEST_PROFILE")" = profile-2-link

    cp "$BOOTSTRAP_OLD_STATE" "$BOOTSTRAP_STATE"
    ln -sfn profile-1-link "$BOOTSTRAP_TEST_PROFILE"
    : > "$BOOTSTRAP_CALLS"
    : > "$BOOTSTRAP_HELPERS"
    (
      cd "$replacement/repo"
      expect_failure verify-rollback run_bootstrap "$replacement/repo" BOOTSTRAP_FAIL_VERIFICATION=1
    )
    grep -qF 'profile rollback --profile' "$BOOTSTRAP_CALLS"
    grep -qF -- '--to 1' "$BOOTSTRAP_CALLS"
    test "$(readlink "$BOOTSTRAP_TEST_PROFILE")" = profile-1-link
    test "$(jq -r '.elements."personal-omp-wsl".storePaths[0]' "$BOOTSTRAP_STATE")" = "$replacement/old-personal-omp-wsl"
    grep -qF old-reconcile "$BOOTSTRAP_HELPERS"
    grep -qF old-verify "$BOOTSTRAP_HELPERS"

    clean_failure=$TMPDIR/clean-failure
    make_repo "$clean_failure/repo"
    export BOOTSTRAP_HOME=$clean_failure/home
    export BOOTSTRAP_TEST_PROFILE=$clean_failure/profiles/profile
    export BOOTSTRAP_NEW_ENVIRONMENT=$clean_failure/new-personal-omp-wsl
    export BOOTSTRAP_STATE=$clean_failure/state.json
    export BOOTSTRAP_OLD_STATE=$clean_failure/old-state.json
    export BOOTSTRAP_CALLS=$clean_failure/nix.calls
    export BOOTSTRAP_HELPERS=$clean_failure/helper.calls
    export BOOTSTRAP_NEW_GENERATION=1
    mkdir -p "$BOOTSTRAP_HOME"
    make_environment "$BOOTSTRAP_NEW_ENVIRONMENT" new
    : > "$BOOTSTRAP_CALLS"
    : > "$BOOTSTRAP_HELPERS"
    (
      cd "$clean_failure/repo"
      expect_failure clean-rollback run_bootstrap "$clean_failure/repo" BOOTSTRAP_FAIL_RECONCILIATION=1
    )
    test "$(jq '.elements | length' "$BOOTSTRAP_STATE")" -eq 0
    grep -qF 'the new profile entry was removed' "$TMPDIR/clean-rollback.output"
    grep -qF 'Preserved mutable Herdr extension for inspection:' "$TMPDIR/clean-rollback.output"
    test ! -e "$BOOTSTRAP_HOME/.omp/agent/config.yml"

    touch $out
  ''
