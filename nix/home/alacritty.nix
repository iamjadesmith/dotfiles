{
  pkgs,
  ...
}: {
  enable = true;
  package = pkgs.unstable.alacritty;

  settings = {
    window = {
      padding = {
        x = 4;
        y = 8;
      };
      decorations = "full";
      opacity = 1;
      startup_mode = "Windowed";
      title = "Alacritty";
      dynamic_title = true;
      decorations_theme_variant = "None";
    };

    general = {
      import = [
        pkgs.alacritty-theme.tokyo-night
      ];
      live_config_reload = true;
    };

    font = let
      jetbrainsMono = style: {
        family = "JetBrainsMono Nerd Font";
        inherit style;
      };
    in {
      size = 14;
      normal = jetbrainsMono "Regular";
      bold = jetbrainsMono "Bold";
      italic = jetbrainsMono "Italic";
      bold_italic = jetbrainsMono "Bold Italic";
    };

    cursor = {
      style = "Block";
    };

    env = {
      TERM = "xterm-256color";
    };

  };
}
