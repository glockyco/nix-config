{
  inputs,
  lib,
  osConfig,
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
    inherit (osConfig.host) ompRuntime;
    inherit (llmAgents) herdr;
    plugin = inputs.personal-omp-plugin.packages.${system}.default;
  };
in

{
  home.packages = [
    personalOmp
    personalOmp.verifyPersonalOmp
    llmAgents.openspec
  ];

  # OMP keeps its executable and runtime state writable. Nix supplies the
  # wrapper, personal plugin, language servers, Herdr, and OpenSpec.
  home.activation.reconcileHerdrOmp = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${lib.getExe personalOmp.reconcileHerdrOmp}
  '';
}
