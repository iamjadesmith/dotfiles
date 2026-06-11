{ ... }:

{
  services.syncthing = {
    enable = true;
    group = "users";
    user = "jade";
    configDir = "/home/jade/.config/syncthing";
    guiAddress = "0.0.0.0:8384";
  };

  systemd.services.syncthing.environment.STNODEFAULTFOLDER = "true";
  networking.firewall.allowedTCPPorts = [ 8384 ];
}
