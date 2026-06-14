{
  config,
  lib,
  meta,
  ...
}:

let
  cfg = config.dotfiles.sops;
in
{
  options.dotfiles.sops = {
    enable = lib.mkEnableOption "shared SOPS host defaults";

    hostName = lib.mkOption {
      type = lib.types.str;
      default = meta.hostname;
      description = "Host name used to locate the default SOPS file.";
    };

    sshKeyPaths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "/etc/ssh/ssh_host_ed25519_key" ];
      description = "SSH host keys used by sops-nix age integration.";
    };

    secrets = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      description = "Host-specific sops-nix secret declarations.";
    };
  };

  config = lib.mkIf cfg.enable {
    sops = {
      defaultSopsFile = ../../secrets + "/${cfg.hostName}/default.yaml";
      age.sshKeyPaths = cfg.sshKeyPaths;
      secrets = cfg.secrets;
    };
  };
}
