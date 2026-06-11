{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    nvidia-container-toolkit
  ];

  hardware.graphics.enable = true;

  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    open = true;
  };

  hardware.nvidia-container-toolkit.enable = true;
}
