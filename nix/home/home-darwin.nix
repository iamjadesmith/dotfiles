{
  config,
  homeDirectory,
  lib,
  meta,
  pkgs,
  user,
  ...
}:

let
  dotfilesDirectory = "${homeDirectory}/.dotfiles";
in
{
  imports = [
    (import ./home.nix {
      inherit
        config
        pkgs
        lib
        meta
        user
        homeDirectory
        ;
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
