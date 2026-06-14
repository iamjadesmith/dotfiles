{
  config,
  pkgs,
  lib,
  meta,
  ...
}:
let
  dotfilesDirectory = "/Users/jade/.dotfiles";
in
{
  imports = [
    (import ../home/home.nix {
      inherit
        config
        pkgs
        lib
        meta
        ;
      user = "jade";
      homeDirectory = "/Users/jade";
      enableAlacritty = true;
      enableAlacrittyTheme = true;
      enableNeovim = false;
      extraConfigFiles = {
        aerospace = ".config/aerospace";
      };
    })
  ];

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
}
