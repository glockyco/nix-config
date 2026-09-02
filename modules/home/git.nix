{
  programs = {
    # Home Manager permits one diff renderer; delta provides syntax-highlighted,
    # word-level diffs. `enableGitIntegration` writes the `core.pager` and
    # `interactive.diffFilter` wiring into the git configuration.
    delta = {
      enable = true;
      enableGitIntegration = true;
    };

    git = {
      enable = true;

      # Git LFS filters require the binary; without it, tracked files remain
      # pointer text.
      lfs.enable = true;

      # The commit identity belongs to the host, because it differs per machine.
      # See `hosts/<name>/default.nix`.
      settings = {
        init.defaultBranch = "main";

        # Only fast-forward or rebase on pull; never create a silent merge.
        pull.rebase = true;
        push.autoSetupRemote = true;

        # `input` normalizes CRLF on commit but leaves checkout line endings
        # unchanged. Files that require CRLF should declare it in `.gitattributes`.
        core.autocrlf = "input";
      };
    };
  };
}
