{ username, ... }:

{
  programs.zed-editor = {
    enable = true;

    # Zed itself comes from the Homebrew cask (modules/darwin/homebrew.nix) so
    # it keeps its own fast release cadence and auto-updater. `null` stops Home
    # Manager installing a second copy from nixpkgs.
    package = null;

    # `mutableUserSettings` is left at its default of true. Home Manager then
    # merges the settings below into Zed's own settings.json during activation
    # instead of symlinking a read-only file -- so Zed can still persist theme,
    # font size and panel state, while the values declared here are re-imposed
    # on every switch. That avoids the failure mode we hit with Karabiner.
    userSettings = {
      # Match the terminal: Catppuccin Mocha, JetBrains Mono without
      # ligatures. Zed ships Catppuccin as a built-in theme, so no extension
      # is required.
      theme = "Catppuccin Mocha";
      buffer_font_family = "JetBrainsMonoNL Nerd Font";
      buffer_font_size = 14;
      terminal.font_family = "JetBrainsMonoNL Nerd Font";

      # Run omp as an external agent inside Zed's agent panel.
      #
      # omp speaks ACP (Agent Client Protocol) natively via `omp acp`: JSON-RPC
      # over stdio, with tool calls routed back through the editor -- `bash`
      # becomes terminal/create, `read` becomes fs/read_text_file, `write`
      # becomes fs/write_text_file -- and writes gated behind
      # session/request_permission. No adapter needed.
      #
      # The command is an absolute path on purpose: Zed launched from Finder or
      # the Dock does not inherit the login shell's PATH. This particular path
      # is a stable symlink maintained by nix-darwin, so it survives rebuilds
      # and always points at the current omp.
      agent_servers.omp = {
        type = "custom";
        command = "/etc/profiles/per-user/${username}/bin/omp";
        args = [ "acp" ];
        env = { };
      };
    };
  };
}
