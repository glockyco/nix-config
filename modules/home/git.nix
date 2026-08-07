{
  programs.git = {
    enable = true;

    # Syntax-highlighted, word-level diffs. Home Manager allows exactly one of
    # delta / diff-so-fancy / difftastic / diff-highlight, so enabling this
    # rules the others out.
    delta.enable = true;

    # Rendered to ~/.config/git/config.
    settings = {
      user = {
        name = "Johann Glock";
        # GitHub's noreply address, so commits are attributable to the account
        # without publishing a real mailbox.
        email = "11704293+glockyco@users.noreply.github.com";
      };

      init.defaultBranch = "main";

      # Only ever fast-forward or rebase on pull; never create a silent merge.
      pull.rebase = true;
      push.autoSetupRemote = true;
    };
  };
}
