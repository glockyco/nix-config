{
  config,
  inputs,
  pkgs,
  ...
}:
{
  imports = [ inputs.nix-index-database.darwinModules.nix-index ];

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    enableAutosuggestions = true;
    enableSyntaxHighlighting = true;
    enableFzfCompletion = false;
    enableFzfGit = false;
    enableFzfHistory = false;
    promptInit = "";
  };
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };
  programs.nix-index.enable = true;

  users.users.${config.host.username} = {
    shell = pkgs.zsh;
    packages = [
      pkgs.openssh
      pkgs.roslyn-language-server
      (pkgs.darwin-switch.override {
        configurationCheckout = config.host.paths.configurationCheckout;
        darwinRebuild = inputs.nix-darwin.packages.${pkgs.stdenv.hostPlatform.system}.darwin-rebuild;
      })
    ];
  };
}
