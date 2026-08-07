{ username, ... }:

{
  programs.zed-editor = {
    enable = true;

    # Homebrew supplies Zed; `package = null` prevents a second nixpkgs copy.
    package = null;

    # Keep `mutableUserSettings = true`: Zed merges these settings into writable
    # settings.json, preserving UI state while reapplying declared values on each switch.
    userSettings = {
      # Catppuccin is built in; no theme extension is needed.
      theme = "Catppuccin Mocha";
      buffer_font_family = "JetBrainsMonoNL Nerd Font";
      buffer_font_size = 14;
      terminal.font_family = "JetBrainsMonoNL Nerd Font";

      # `omp acp` speaks ACP over stdio; Zed routes tool calls and permission requests through its agent panel.
      # Use an absolute path because GUI-launched Zed does not inherit the login shell's PATH.
      agent_servers.omp = {
        type = "custom";
        command = "/etc/profiles/per-user/${username}/bin/omp";
        args = [ "acp" ];
        env = { };
      };
    };
  };
}
