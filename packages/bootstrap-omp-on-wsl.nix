{
  coreutils,
  environment,
  git,
  gnugrep,
  jq,
  lib,
  writeShellApplication,
}:

let
  repositoryEmail = "11704293+glockyco@users.noreply.github.com";
in
writeShellApplication {
  name = "bootstrap-omp-on-wsl";
  runtimeInputs = [
    coreutils
    git
    gnugrep
    jq
  ];

  text = ''
    : "''${HOME:?HOME must be set}"

    nix_bin="''${BOOTSTRAP_NIX_BIN:-nix}"
    git_bin="''${BOOTSTRAP_GIT_BIN:-git}"
    uname_bin="''${BOOTSTRAP_UNAME_BIN:-uname}"
    environment="''${BOOTSTRAP_ENVIRONMENT:-${environment}}"
    profile="''${BOOTSTRAP_PROFILE:-''${NIX_PROFILE:-''${XDG_STATE_HOME:-$HOME/.local/state}/nix/profiles/profile}}"

    kernel_name="''${BOOTSTRAP_KERNEL_NAME:-$($uname_bin -s)}"
    kernel_release="''${BOOTSTRAP_KERNEL_RELEASE:-$($uname_bin -r)}"
    machine="''${BOOTSTRAP_MACHINE:-$($uname_bin -m)}"

    if [ "$kernel_name" != Linux ]; then
      printf 'bootstrap-omp-on-wsl: unsupported kernel: %s\n' "$kernel_name" >&2
      exit 2
    fi
    case "''${kernel_release,,}" in
      *microsoft-standard* | *wsl2*) ;;
      *)
        printf 'bootstrap-omp-on-wsl: WSL 2 is required; kernel release is %s\n' "$kernel_release" >&2
        exit 2
        ;;
    esac
    if [ "$machine" != x86_64 ]; then
      printf 'bootstrap-omp-on-wsl: unsupported architecture: %s; expected x86_64\n' "$machine" >&2
      exit 2
    fi

    repo_root="$($git_bin rev-parse --show-toplevel 2>/dev/null)" || {
      printf 'bootstrap-omp-on-wsl: run this command from the nix-config Git worktree root\n' >&2
      exit 2
    }
    if [ "$(realpath "$repo_root")" != "$(realpath "$PWD")" ]; then
      printf 'bootstrap-omp-on-wsl: run this command from the nix-config Git worktree root: %s\n' "$repo_root" >&2
      exit 2
    fi
    test -f "$repo_root/flake.nix"
    test -f "$repo_root/flake.lock"

    "$git_bin" config --local user.email ${lib.escapeShellArg repositoryEmail}

    mkdir -p "$(dirname "$profile")"

    previous_generation=
    previous_personal=0
    if [ -e "$profile" ]; then
      previous_target="$(readlink "$profile")"
      previous_name="$(basename "$previous_target")"
      case "$previous_name" in
        profile-*-link)
          previous_generation="''${previous_name#profile-}"
          previous_generation="''${previous_generation%-link}"
          ;;
        *)
          printf 'bootstrap-omp-on-wsl: cannot identify the current profile generation from %s\n' "$previous_target" >&2
          exit 1
          ;;
      esac
      if [ -x "$profile/bin/reconcile-herdr-omp" ] && [ -x "$profile/bin/verify-personal-omp" ]; then
        previous_personal=1
      fi
    fi

    list_profile() {
      if [ -e "$profile" ]; then
        "$nix_bin" profile list --profile "$profile" --json
      else
        printf '%s\n' '{"elements":{}}'
      fi
    }

    personal_entries() {
      jq -r '
        .elements
        | to_entries[]
        | select(any(.value.storePaths[]?; endswith("-personal-omp-wsl")))
        | .key
      '
    }

    exact_entries() {
      jq -r --arg environment "$environment" '
        .elements
        | to_entries[]
        | select(any(.value.storePaths[]?; . == $environment))
        | .key
      '
    }

    cleanup_clean_install() {
      if [ ! -e "$profile" ]; then
        return
      fi
      current_json="$(list_profile)"
      while IFS= read -r entry; do
        if [ -n "$entry" ]; then
          "$nix_bin" profile remove --profile "$profile" "$entry"
        fi
      done < <(printf '%s\n' "$current_json" | exact_entries)
    }

    profile_changed=0
    rollback() {
      status=$?
      trap - ERR
      recovery=unchanged
      if [ "$profile_changed" -eq 1 ]; then
        if [ -n "$previous_generation" ]; then
          recovery=failed
          if "$nix_bin" profile rollback --profile "$profile" --to "$previous_generation"; then
            recovery=restored
            if [ "$previous_personal" -eq 1 ]; then
              recovery=verified
              if ! "$profile/bin/reconcile-herdr-omp" || ! "$profile/bin/verify-personal-omp"; then
                recovery=unverified
              fi
            fi
          fi
        elif cleanup_clean_install; then
          recovery=removed
        else
          recovery=failed
        fi
      fi

      case "$recovery" in
        unchanged) printf 'bootstrap-omp-on-wsl: installation failed before the profile changed\n' >&2 ;;
        restored) printf 'bootstrap-omp-on-wsl: installation failed; the previous profile was restored\n' >&2 ;;
        verified) printf 'bootstrap-omp-on-wsl: installation failed; the previous personal OMP profile was restored and verified\n' >&2 ;;
        removed) printf 'bootstrap-omp-on-wsl: installation failed; the new profile entry was removed\n' >&2 ;;
        unverified) printf 'bootstrap-omp-on-wsl: installation failed; the previous profile was restored but did not verify\n' >&2 ;;
        failed) printf 'bootstrap-omp-on-wsl: installation failed and automatic profile recovery failed\n' >&2 ;;
      esac
      if [ -e "$HOME/.omp/agent/extensions/herdr-omp-agent-state.ts" ]; then
        printf 'Preserved mutable Herdr extension for inspection: %s\n' \
          "$HOME/.omp/agent/extensions/herdr-omp-agent-state.ts" >&2
      fi
      exit "$status"
    }
    trap rollback ERR

    profile_json="$(list_profile)"
    personal_count="$(printf '%s\n' "$profile_json" | personal_entries | grep -c . || true)"
    exact_count="$(printf '%s\n' "$profile_json" | exact_entries | grep -c . || true)"

    if [ "$personal_count" -ne 1 ] || [ "$exact_count" -ne 1 ]; then
      while IFS= read -r entry; do
        if [ -n "$entry" ]; then
          "$nix_bin" profile remove --profile "$profile" "$entry"
          profile_changed=1
        fi
      done < <(printf '%s\n' "$profile_json" | personal_entries)

      "$nix_bin" profile add --profile "$profile" "$environment"
      profile_changed=1
    fi

    "$profile/bin/reconcile-herdr-omp"
    "$profile/bin/verify-personal-omp"

    trap - ERR
    printf 'bootstrap-omp-on-wsl: ready\n'
    printf 'Profile: %s\n' "$profile"
    printf 'Git email: %s\n' "$("$git_bin" config --local user.email)"
  '';

  passthru = {
    inherit environment repositoryEmail;
  };
}
