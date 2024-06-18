{ config, pkgs, inputs, ... }:
let inherit (config.lib.file) mkOutOfStoreSymlink;
in {
  home.username = "joejad";
  home.homeDirectory = "/home/joejad";
  xdg.enable = true;

  xdg.configFile.nvim.source =
    mkOutOfStoreSymlink "/home/joejad/.dotfiles/.config/nvim";

  home.stateVersion = "24.05";

  home.packages = [ ];

  home.file = { };

  home.sessionVariables = { };

  programs.home-manager.enable = true;

  wayland.windowManager.hyprland = {
    enable = true;

    plugins = [
      inputs.hyprland-plugins.packages."${pkgs.system}".borders-plus-plus
    ];

    settings = {
        "plugin:borders-plus-plus" = {
            add_borders = 1;

            "col.border_1" = "rgb(ffffff)";
            "col.border_2" = "rgb(2222ff)";

            border_size_1 = 10;
            border_size_2 = -1;

            natural_rounding = "yes";
        };
    };
  };
}
