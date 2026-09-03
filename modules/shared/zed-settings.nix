{
  ompCommand,
  ompArgs ? [ "acp" ],
}:

{
  buffer_font_family = "JetBrainsMonoNL Nerd Font";
  buffer_font_size = 14;
  terminal.font_family = "JetBrainsMonoNL Nerd Font";

  vim_mode = true;
  base_keymap = "VSCode";
  ui_font_size = 16;
  show_edit_predictions = false;
  diff_view_style = "unified";

  agent_servers.omp = {
    type = "custom";
    command = ompCommand;
    args = ompArgs;
    env = { };
  };
}
