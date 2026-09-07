{
  herdr,
  lib,
  markdownOxide,
  pkgs,
  plugin,
  roslynLanguageServer,
}:

let
  devUpdate = pkgs.callPackage ./omp-dev-update.nix { inherit plugin; };

  languageServers = with pkgs; [
    markdownOxide
    nixd
    pyright
    roslynLanguageServer
    svelte-language-server
    texlab
    typescript-language-server
  ];

  resolveGeneration = ''
    : "''${HOME:?HOME must be set}"
    current="$HOME/.local/share/omp-dev/current"
    if [ ! -L "$current" ] || ! generation="$(${pkgs.coreutils}/bin/readlink -e "$current")"; then
      printf 'No OMP source generation is selected at %s.\nRun omp-dev-update to initialize it.\n' "$current" >&2
      exit 1
    fi
    omp_bin="$generation/omp"
    if [ ! -f "$omp_bin" ] || [ ! -x "$omp_bin" ]; then
      printf 'OMP source launcher is missing or unusable at %s.\nRun omp-dev-update to prepare a generation.\n' "$omp_bin" >&2
      exit 1
    fi
  '';

  reconcileHerdrOmp = pkgs.writeShellApplication {
    name = "reconcile-herdr-omp";
    runtimeInputs = [ pkgs.gnugrep ];
    text = ''
      : "''${HOME:?HOME must be set}"

      herdr_bin="''${HERDR_BIN:-${lib.getExe herdr}}"
      agent_dir="''${OMP_AGENT_DIR:-$HOME/.omp/agent}"
      extension="$agent_dir/extensions/herdr-omp-agent-state.ts"

      # Herdr owns the generated extension, but its installer requires the OMP
      # agent root to exist even for a user who has never launched OMP.
      mkdir -p "$agent_dir"

      if [ ! -f "$extension" ]; then
        "$herdr_bin" integration install omp
        exit 0
      fi

      status="$($herdr_bin integration status --outdated-only)"
      if printf '%s\n' "$status" | grep -q '^omp:'; then
        "$herdr_bin" integration install omp
      fi
    '';
  };

  verifyPersonalOmp = pkgs.writeShellApplication {
    name = "verify-personal-omp";
    runtimeInputs = [
      pkgs.gnugrep
      pkgs.jq
    ];
    text = ''
      ${resolveGeneration}
      metadata="$(${lib.getExe devUpdate} --status)"
      if ! jq -e --argjson selected "$metadata" '. == $selected' "$generation/generation.json" >/dev/null; then
        printf 'OMP selection changed during verification. Run verify-personal-omp again.\n' >&2
        exit 1
      fi
      herdr_bin="''${HERDR_BIN:-${lib.getExe herdr}}"
      plugin_dir=${plugin}

      test -f "$plugin_dir/package.json"
      test -f "$plugin_dir/extensions/personal-commit.ts"
      test -f "$plugin_dir/lsp/lsp.json"
      test -d "$plugin_dir/commands"
      test ! -e "$plugin_dir/lsp/commands"

      omp_version="$("$omp_bin" --extension "$plugin_dir" --plugin-dir "$plugin_dir/lsp" --version)"
      test -n "$omp_version"

      herdr_status="$($herdr_bin integration status)"
      omp_status="$(printf '%s\n' "$herdr_status" | grep '^omp:' || true)"
      if ! printf '%s\n' "$omp_status" | grep -q '^omp: current'; then
        printf 'Herdr OMP integration is not current:\n%s\n' "$omp_status" >&2
        exit 1
      fi

      printf '%s\n' "$metadata" | jq -r '"Release: \(.release)\nUpstream: \(.upstream)\nPatch: \(.patchBase)..\(.patchTip)\nCommit: \(.commit)\nSystem: \(.system)"'
      printf 'OMP: %s\nPlugin: %s\n%s\n' "$omp_version" "$plugin_dir" "$omp_status"
    '';
  };

  wrapper = pkgs.writeShellApplication {
    name = "omp";
    runtimeInputs = languageServers;
    text = ''
      if [ "''${1-}" = update ]; then
        printf 'Use omp-dev-update to update the patched OMP source generation.\n' >&2
        exit 1
      fi
      ${resolveGeneration}

      # Each flag is aimed at what only it provides. --extension loads the
      # personal_commit extension, the skills, the rules, and the OpenSpec
      # workflow commands. --plugin-dir loads the LSP overrides, and points at
      # the scoped lsp/ root: aiming it at the package root would rescan
      # commands/ and register every workflow command a second time under a
      # store-derived name.
      exec "$omp_bin" --extension ${plugin} --plugin-dir ${plugin}/lsp "$@"
    '';
  };
in
wrapper.overrideAttrs (old: {
  passthru = (old.passthru or { }) // {
    inherit
      devUpdate
      languageServers
      plugin
      reconcileHerdrOmp
      verifyPersonalOmp
      ;
  };
})
