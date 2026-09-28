{ ... }:

let
  scansPath = "/mnt/data/scans";
in
{
  # Dedicated account for the printer's scan-to-SMB feature. Samba passwords
  # are stored separately from the system password: `sudo smbpasswd -a scanner`.
  users.users.scanner = {
    isSystemUser = true;
    group = "users";
    description = "Printer scan-to-SMB account";
  };

  systemd.tmpfiles.rules = [
    "d ${scansPath} 2775 scanner users -"
  ];

  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        "server string" = "mjolnir";
        "hosts allow" = "10.3.0. 10.10.10. 10.26.27. 100.64.0.0/10 127.0.0.1 ::1";
        "hosts deny" = "0.0.0.0/0";
        "map to guest" = "never";
        "load printers" = "no";
      };
      scans = {
        path = scansPath;
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "valid users" = "scanner jade";
        "force group" = "users";
        "create mask" = "0664";
        "directory mask" = "2775";
      };
    };
  };
}
