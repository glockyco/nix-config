{ inputs, pkgs, ... }:

let
  llmAgents = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
in

{
  home.packages = [
    llmAgents.omp

    llmAgents.herdr
  ];
}
