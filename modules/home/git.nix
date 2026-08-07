{
  programs.git = {
    enable = true;

    # Syntax-highlighted, word-level diffs. Home Manager allows exactly one of
    # delta / diff-so-fancy / difftastic / diff-highlight, so enabling this
    # rules the others out.
    delta.enable = true;

    # Installs git-lfs and registers its filters. The previous machine had the
    # lfs filter in its ~/.gitconfig; without the binary present, LFS-tracked
    # files check out as pointer text instead of content.
    lfs.enable = true;

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

      # `input` converts CRLF to LF on commit and does nothing on checkout.
      # git-scm's own guidance for macOS: "you don't want Git to automatically
      # convert them when you check out files; however, if a file with CRLF
      # endings accidentally gets introduced, then you may want Git to fix it."
      #
      # Deliberately not `true` -- that is the documented Windows setting and
      # forces a CRLF working tree everywhere. Files that must keep CRLF belong
      # in a repository's own .gitattributes, since that is repository policy.
      core.autocrlf = "input";
    };
  };
}
