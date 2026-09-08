{
  inputs,
  lib,
  pkgs,
  ...
}:

let
  system = pkgs.stdenv.hostPlatform.system;
  llmAgents = inputs.llm-agents.packages.${system};
  markdownOxide = pkgs.callPackage ../../packages/markdown-oxide.nix { };
  roslynLanguageServer = pkgs.callPackage ../../packages/roslyn-language-server.nix { };
  personalOmp = pkgs.callPackage ../../packages/personal-omp.nix {
    inherit
      markdownOxide
      roslynLanguageServer
      ;
    inherit (llmAgents) herdr;
    plannotator = inputs.plannotator-packages.packages.${system}.plannotator;
    plugin = inputs.personal-omp-plugin.packages.${system}.default;
  };
in

{
  home.packages = [
    personalOmp
    personalOmp.devUpdate
    personalOmp.verifyPersonalOmp
    llmAgents.openspec
  ];

  # Source preparation is explicit. Activation reconciles Herdr without
  # preparing or launching OMP, and leaves source selection unchanged.
  home.activation.reconcileHerdrOmp = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${lib.getExe personalOmp.reconcileHerdrOmp}
  '';
}
