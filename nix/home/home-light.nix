{
  config,
  pkgs,
  lib,
  meta,
  ...
}:
let
  inherit (config.lib.file) mkOutOfStoreSymlink;
in
{
  home.username = "joejad";
  home.homeDirectory = "/home/joejad";
  xdg.enable = true;

  xdg.configFile.nvim.source = mkOutOfStoreSymlink "/home/joejad/.dotfiles/.config/nvim";
  xdg.configFile.swaync.source = mkOutOfStoreSymlink "/home/joejad/.dotfiles/.config/swaync";
  xdg.configFile.waybar.source = mkOutOfStoreSymlink "/home/joejad/.dotfiles/.config/waybar";
  xdg.configFile.wofi.source = mkOutOfStoreSymlink "/home/joejad/.dotfiles/.config/wofi";
  # xdg.configFile.opencode.source = mkOutOfStoreSymlink "/home/joejad/.dotfiles/.config/opencode/opencode.json";

  home.stateVersion = "24.05";

  home.packages = [ ];

  home.file = { };

  home.sessionVariables = { };

  programs.home-manager.enable = true;

  gtk = {
    enable = true;
  };

  home.pointerCursor = {
    gtk.enable = true;
    package = pkgs.rose-pine-cursor;
    name = "BreezeX-RosePine-Linux";
    size = 24;
  };

  dconf = {
    enable = true;
  };

  programs = {
    alacritty = import ./alacritty-light.nix {
      inherit
        config
        pkgs
        lib
        meta
        ;
    };
    zsh = import ./zsh.nix { inherit config; };
    fzf = import ./fzf.nix { inherit pkgs; };
    firefox = import ./firefox.nix;
    opencode = import ./opencode.nix;
    neovim = import ./neovim.nix { inherit config pkgs; };
    tmux = import ./tmux.nix { inherit pkgs; };
    git = import ./git.nix { inherit config pkgs; };
    zoxide = import ./zoxide.nix { inherit pkgs; };
  };

  wayland.windowManager = {
    hyprland = import ./hyprland-light.nix { inherit config; };
  };

}
