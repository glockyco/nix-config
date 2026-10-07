let
  data = (builtins.fromTOML (builtins.readFile ../../home/.chezmoidata/zed.toml)).zed;
in
{
  fontFamily ? data.fontFamily,
}:

data.settings
// {
  buffer_font_family = fontFamily;
  terminal.font_family = fontFamily;
  theme = {
    dark = data.themeName;
    light = data.themeName;
  };

}
