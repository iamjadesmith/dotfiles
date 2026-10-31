{ pkgs, ... }:

{
  # Started from the TTY with `Hyprland`, so nothing here runs until you log in.
  programs.hyprland.enable = true;

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  fonts.packages = [ pkgs.nerd-fonts.jetbrains-mono ];

  environment.systemPackages = [ pkgs.wofi ];
}
