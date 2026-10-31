{
  config,
  homeDirectory,
  meta,
  pkgs,
  ...
}:

{
  imports = [ ./home-server.nix ];

  xdg.configFile.wofi.source = config.lib.file.mkOutOfStoreSymlink "${homeDirectory}/.dotfiles/.config/wofi";

  programs.firefox = import ./firefox.nix;
  programs.ghostty = import ./ghostty.nix { inherit meta pkgs; };

  wayland.windowManager.hyprland = import ./hyprland.nix { inherit config; };
}
