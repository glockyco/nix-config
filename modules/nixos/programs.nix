{ inputs, ... }:
{
  imports = [ inputs.nix-index-database.nixosModules.nix-index ];

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    promptInit = "";
  };
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };
  programs.nix-index.enableZshIntegration = true;
}
