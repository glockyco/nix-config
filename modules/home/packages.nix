{ inputs, pkgs, ... }:

let
  # Taken from llm-agents.nix's own package set rather than through its overlay,
  # so the closure matches upstream CI and substitutes from cache.numtide.com
  # (configured in modules/darwin/nix.nix).
  llmAgents = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
in

{
  home.packages = [
    # Oh My Pi.
    #
    # omp keeps all of its runtime state outside the Nix store, under
    # ~/.omp/agent (credential database, config.yml, secrets.yml, .env). None of
    # that belongs in this repository; authenticate once with `/login` inside a
    # session after activation.
    llmAgents.omp

    # Keeps agent terminals alive across disconnects and reattaches them.
    llmAgents.herdr
  ];
}
