{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    prismlauncher
  ];

  programs.steam = {
    enable = true;
    extraCompatPackages = [
      pkgs.proton-ge-bin
    ];
    gamescopeSession.enable = true;
  };
}
