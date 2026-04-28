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
  xdg.configFile."opencode/opencode.json".source =
    mkOutOfStoreSymlink "${dotfilesDirectory}/.config/opencode/opencode.json";
  xdg.configFile."starship.toml".source =
    mkOutOfStoreSymlink "${dotfilesDirectory}/.config/starship.toml";

  home.stateVersion = "24.05";

  home.packages = [ ];

  home.file = { };

  home.sessionVariables = { };

  programs.home-manager.enable = true;

  programs = {
    zsh = import ./zsh.nix { inherit config; };
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
    fzf = import ./fzf.nix { inherit pkgs; };
    neovim = import ./neovim.nix { inherit config pkgs; };
    tmux = import ./tmux.nix { inherit pkgs; };
    git = import ./git.nix { inherit config pkgs; };
    zoxide = import ./zoxide.nix { inherit pkgs; };
    starship.enable = true;
  };

}
