{
  herdr,
  lib,
  ompRuntime,
  pkgs,
  plugin,
}:

let
  ompExecutableValue =
    if ompRuntime.executable ? absolute then
      toString ompRuntime.executable.absolute
    else
      "$HOME/${ompRuntime.executable.homeRelative}";
  ompExecutable = ''"${ompExecutableValue}"'';
  inherit (ompRuntime) installCommand;

  binaryDotnetCorePackages = pkgs.dotnetCorePackages.overrideScope (
    _final: previous: {
      runtime_9_0 = previous."runtime_9_0-bin";
      sdk_8_0 = previous."sdk_8_0-bin";
      sdk_9_0 = previous."sdk_9_0-bin";
      sdk_10_0 = previous."sdk_10_0-bin";
    }
  );
  marksmanBinary = pkgs.marksman.override {
    dotnetCorePackages = binaryDotnetCorePackages;
  };
  roslynLs = pkgs.roslyn-ls.override {
    dotnetCorePackages = binaryDotnetCorePackages;
  };
  languageServers = with pkgs; [
    marksmanBinary
    nixd
    pyright
    roslynLs
    svelte-language-server
    texlab
    typescript-language-server
  ];

  requireOmpExecutable = ''
    if [ ! -x "$omp_bin" ]; then
      # Keep variables literal so the displayed install command remains reusable.
      # shellcheck disable=SC2016
      printf 'oh-my-pi executable not found at %s.\nInstall it with:\n  %s\n' \
        "$omp_bin" ${lib.escapeShellArg installCommand} >&2
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
    runtimeInputs = [ pkgs.gnugrep ];
    text = ''
      omp_bin="''${OMP_BIN:-${ompExecutableValue}}"
      herdr_bin="''${HERDR_BIN:-${lib.getExe herdr}}"
      plugin_dir="''${PERSONAL_OMP_PLUGIN_DIR:-${plugin}}"

      ${requireOmpExecutable}

      test -f "$plugin_dir/package.json"
      test -f "$plugin_dir/extensions/personal-commit.ts"
      test -f "$plugin_dir/lsp/lsp.json"
      test -d "$plugin_dir/commands"
      test ! -e "$plugin_dir/lsp/commands"

      omp_version="$($omp_bin --extension "$plugin_dir" --plugin-dir "$plugin_dir/lsp" --version)"
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
      # Each flag is aimed at what only it provides. --extension loads the
      # personal_commit extension, the skills, the rules, and the OpenSpec
      # workflow commands. --plugin-dir loads the LSP overrides, and points at
      # the scoped lsp/ root: aiming it at the package root would rescan
      # commands/ and register every workflow command a second time under a
      # store-derived name.
      omp_bin=${ompExecutable}
      ${requireOmpExecutable}
      exec "$omp_bin" --extension ${plugin} --plugin-dir ${plugin}/lsp "$@"
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
    inherit ompExecutable ompRuntime;
    ompInstallCommand = installCommand;
  };
})
