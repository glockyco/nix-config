{
  inputs,
  lib,
  pkgs,
  ...
}:

let
  system = pkgs.stdenv.hostPlatform.system;
  llmAgents = inputs.llm-agents.packages.${system};
  personalOmp = pkgs.callPackage ../../packages/personal-omp.nix {
    inherit (llmAgents) herdr omp;
    plugin = inputs.personal-omp-plugin.packages.${system}.default;
  };
in

{
  home.packages = [
    personalOmp
    llmAgents.openspec
  ];

  # OMP keeps authentication, configuration, sessions, history, caches, and logs
  # in its writable state directory. Nix supplies executable inputs only.
  home.activation.reconcileHerdrOmp = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${lib.getExe personalOmp.reconcileHerdrOmp}
  '';

  home.activation.verifyPersonalOmp = lib.hm.dag.entryAfter [ "reconcileHerdrOmp" ] ''
    run ${lib.getExe personalOmp.verifyPersonalOmp}
  '';
}
