{
  config,
  pkgs,
  lib,
  meta,
  user,
  homeDirectory,
  ...
}:
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
    })
  ];

  programs = {
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };

  home.sessionPath = [ "${homeDirectory}/.opencode/bin" ];
}
