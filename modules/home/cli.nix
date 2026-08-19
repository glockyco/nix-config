{ config, lib, ... }:
{
  # Home Manager modules provide shell integration; installing fzf as a package
  # alone does not rebind Ctrl-R.
  programs = {
    fzf = {
      enable = true;
      # Exclude .git so pickers do not traverse repository object files.
      defaultCommand = "fd --type f --hidden --exclude .git";
      fileWidgetCommand = "fd --type f --hidden --exclude .git";
      changeDirWidgetCommand = "fd --type d --hidden --exclude .git";

      # Replaced below. The module guards the integration with
      # `[[ $options[zle] = on ]]`, which reports "on" in an interactive shell
      # that has no terminal. fzf snapshots the whole option array and restores
      # it with one `eval`, which then cannot set `zle`. omp runs `!` commands
      # through `zsh -l -i` with stdin on /dev/null, so each one printed
      # `(eval):1: can't change option: zle` twice.
      enableZshIntegration = false;
    };

    # Same order the fzf module uses, so this still loads after compinit.
    zsh.initContent = lib.mkOrder 910 ''
      if [[ -t 0 ]]; then
        source <(${lib.getExe config.programs.fzf.package} --zsh)
      fi
    '';

    zoxide.enable = true;

    ripgrep.enable = true;
    fd.enable = true;
    bat.enable = true;

    eza = {
      enable = true;
      git = true;
      icons = "auto";
    };
  };
}
