{
  config,
  pkgs,
  lib,
  meta,
  user,
  homeDirectory,
  ...
}:
let
  inherit (config.lib.file) mkOutOfStoreSymlink;
  dotfilesDirectory = "${homeDirectory}/.dotfiles";
in
{
  home.username = user;
  home.homeDirectory = homeDirectory;
  xdg.enable = true;

  xdg.configFile.nvim.source = mkOutOfStoreSymlink "${dotfilesDirectory}/.config/nvim";
  xdg.configFile.swaync.source = mkOutOfStoreSymlink "${dotfilesDirectory}/.config/swaync";
  xdg.configFile.waybar.source = mkOutOfStoreSymlink "${dotfilesDirectory}/.config/waybar";
  xdg.configFile.wofi.source = mkOutOfStoreSymlink "${dotfilesDirectory}/.config/wofi";
  xdg.configFile."opencode/opencode.json".source =
    mkOutOfStoreSymlink "${dotfilesDirectory}/.config/opencode/opencode.json";
  xdg.configFile."starship.toml".source =
    mkOutOfStoreSymlink "${dotfilesDirectory}/.config/starship.toml";

  home.stateVersion = "24.05";

  home.packages = [ ];

  home.file = { };

  home.sessionVariables = { };

  programs.home-manager.enable = true;

  gtk = {
    enable = true;
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
  };

  home.pointerCursor = {
    x11.enable = true;
    gtk.enable = true;
    package = pkgs.rose-pine-cursor;
    name = "BreezeX-RosePine-Linux";
    size = 24;
  };

  dconf = {
    enable = true;
    settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";
  };

  programs = {
    alacritty = import ./alacritty.nix {
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
    neovim = import ./neovim.nix { inherit config pkgs; };
    tmux = import ./tmux.nix { inherit pkgs; };
    git = import ./git.nix { inherit config pkgs; };
    zoxide = import ./zoxide.nix { inherit pkgs; };
    starship.enable = true;
  };

  wayland.windowManager = {
    hyprland = import ./hyprland.nix { inherit config; };
  };

}
