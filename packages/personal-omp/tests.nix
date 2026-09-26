{ pkgs, ... }:

let
  personalOmp = pkgs.personal-omp;
  common = {
    OMP_WRAPPER = "${personalOmp}/bin/omp";
    OMP_PLUGIN = toString personalOmp.plugin;
    OMP_PLANNOTATOR = pkgs.lib.getExe personalOmp.plannotator;
  };
in
{
  personalOmpShape = pkgs.runCommand "check-personal-omp-shape" (
    common
    // {
      nativeBuildInputs = [ pkgs.jq ] ++ personalOmp.languageServers;
      OMP_UPDATER = "${personalOmp.devUpdate}/bin/omp-dev-update";
      OMP_VERIFIER = pkgs.lib.getExe personalOmp.verifyPersonalOmp;
    }
  ) "${pkgs.runtimeShell} ${./shape.sh}";

  personalOmpGeneration = pkgs.runCommand "check-personal-omp-generation" (
    common
    // {
      nativeBuildInputs = [ pkgs.python3 ];
      OMP_NIXD = "${pkgs.nixd}/bin/nixd";
      OMP_PYTHON = "${pkgs.python3}/bin/python3";
      GENERATION_PROBE = ./generation-probe.py;
      CONFLICTING_PLANNOTATOR = ./conflicting-plannotator.sh;
      GENERATION_DRIVER = ./generation.py;
    }
  ) "${pkgs.runtimeShell} ${./generation.sh}";

  personalOmpVerification = pkgs.runCommand "check-personal-omp-verification" (
    common
    // {
      nativeBuildInputs = [ pkgs.python3 ];
      OMP_VERIFIER = pkgs.lib.getExe personalOmp.verifyPersonalOmp;
      OMP_PYTHON = "${pkgs.python3}/bin/python3";
      OMP_BASH = toString pkgs.bash;
      OMP_SYSTEM = pkgs.stdenv.hostPlatform.system;
      OMP_PLANNOTATOR_VERSION = personalOmp.plannotator.version;
      VERSION_PROBE = ./version-probe.py;
      HERDR_PROBE = ./herdr-verification-probe.py;
      VERIFICATION_DRIVER = ./verification.py;
    }
  ) "${pkgs.runtimeShell} ${./verification.sh}";

  herdrOmpReconciliation = pkgs.runCommand "check-herdr-omp-reconciliation" {
    HERDR_STUB = ./herdr-stub.sh;
    OMP_BASH_BIN = "${pkgs.bash}/bin/bash";
    HERDR_RECONCILE = pkgs.lib.getExe personalOmp.reconcileHerdrOmp;
  } "${pkgs.runtimeShell} ${./reconciliation.sh}";
}
