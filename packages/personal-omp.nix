{
  herdr,
  lib,
  omp,
  pkgs,
  plugin,
}:

let
  languageServers = with pkgs; [
    marksman
    nixd
    pyright
    roslyn-ls
    svelte-language-server
    texlab
    typescript-language-server
  ];

  reconcileHerdrOmp = pkgs.writeShellApplication {
    name = "reconcile-herdr-omp";
    runtimeInputs = [ pkgs.gnugrep ];
    text = ''
      : "''${HOME:?HOME must be set}"

      herdr_bin="''${HERDR_BIN:-${lib.getExe herdr}}"
      agent_dir="''${OMP_AGENT_DIR:-$HOME/.omp/agent}"
      extension="$agent_dir/extensions/herdr-omp-agent-state.ts"

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
    runtimeInputs = [ pkgs.gnugrep ];
    text = ''
      omp_bin="''${OMP_BIN:-${lib.getExe omp}}"
      herdr_bin="''${HERDR_BIN:-${lib.getExe herdr}}"
      plugin_dir="''${PERSONAL_OMP_PLUGIN_DIR:-${plugin}}"

      test -f "$plugin_dir/package.json"
      test -f "$plugin_dir/extensions/personal-commit.ts"
      test -f "$plugin_dir/lsp.json"

      omp_version="$($omp_bin --plugin-dir "$plugin_dir" --extension "$plugin_dir" --version)"
      test -n "$omp_version"

      herdr_status="$($herdr_bin integration status)"
      omp_status="$(printf '%s\n' "$herdr_status" | grep '^omp:' || true)"
      if ! printf '%s\n' "$omp_status" | grep -q '^omp: current'; then
        printf 'Herdr OMP integration is not current:\n%s\n' "$omp_status" >&2
        exit 1
      fi

      printf 'OMP: %s\nPlugin: %s\n%s\n' "$omp_version" "$plugin_dir" "$omp_status"
    '';
  };

  wrapper = pkgs.writeShellApplication {
    name = "omp";
    runtimeInputs = languageServers;
    text = ''
      exec ${lib.getExe omp} --plugin-dir ${plugin} --extension ${plugin} "$@"
    '';
  };
in
wrapper.overrideAttrs (old: {
  passthru = (old.passthru or { }) // {
    inherit
      languageServers
      plugin
      reconcileHerdrOmp
      verifyPersonalOmp
      ;
    upstreamOmp = omp;
  };
})
