{
  config,
  pkgs,
  lib,
  meta,
  ...
}:
let
  inherit (config.lib.file) mkOutOfStoreSymlink;
  dotfilesDirectory = "/Users/jade/.dotfiles";
in
{
  programs.home-manager.enable = true;

  home.username = "jade";
  home.homeDirectory = "/Users/jade";
  xdg.enable = true;

  xdg.configFile.nvim.source = mkOutOfStoreSymlink "${dotfilesDirectory}/.config/nvim";
  xdg.configFile.aerospace.source = mkOutOfStoreSymlink "${dotfilesDirectory}/.config/aerospace";
  xdg.configFile."opencode/opencode.json".source =
    mkOutOfStoreSymlink "${dotfilesDirectory}/.config/opencode/opencode.json";
  xdg.configFile."starship.toml".source =
    mkOutOfStoreSymlink "${dotfilesDirectory}/.config/starship.toml";
  xdg.configFile."alacritty/themes/tokyonight.toml".source =
    mkOutOfStoreSymlink "${dotfilesDirectory}/.config/alacritty/tokyonight-night.toml";
  xdg.configFile."alacritty/themes/catppuccin-latte.toml".source =
    mkOutOfStoreSymlink "${dotfilesDirectory}/.config/alacritty/catppuccin-latte.toml";

  home.stateVersion = "24.05";

  home.activation.initTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -e "$HOME/.config/theme-mode" ]; then
      printf '%s\n' dark > "$HOME/.config/theme-mode"
    fi

    if [ ! -e "$HOME/.config/alacritty/theme.toml" ]; then
      mkdir -p "$HOME/.config/alacritty"
      cp "${dotfilesDirectory}/.config/alacritty/tokyonight-night.toml" "$HOME/.config/alacritty/theme.toml"
    fi
  '';

  launchd.agents.theme-mode-sync = {
    enable = true;
    config = {
      ProgramArguments = [
        "${dotfilesDirectory}/scripts/theme-mode"
        "sync-macos"
      ];
      RunAtLoad = true;
      StartInterval = 300;
      StandardOutPath = "/tmp/theme-mode-sync.out.log";
      StandardErrorPath = "/tmp/theme-mode-sync.err.log";
    };
  };

  programs = {
    alacritty = import ../home/alacritty.nix {
      inherit
        lib
        config
        pkgs
        meta
        ;
    };
    tmux = import ../home/tmux.nix { inherit pkgs; };
    zsh = import ../home/zsh.nix { inherit config pkgs lib; };
    zoxide = (import ../home/zoxide.nix { inherit config pkgs; });
    fzf = import ../home/fzf.nix { inherit pkgs; };
    git = import ../home/git.nix { inherit config pkgs; };
    starship.enable = true;
  };
}
