{
  config,
  lib,
  ...
}:

let
  cfg = config.dotfiles.docker;
in
{
  options.dotfiles.docker = {
    enable = lib.mkEnableOption "shared Docker defaults";

    storageDriver = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Optional Docker storage driver.";
    };

    logDriver = lib.mkOption {
      type = lib.types.str;
      default = "json-file";
      description = "Docker log driver.";
    };

    cdi = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to enable CDI support in Docker daemon settings.";
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.docker = {
      enable = true;
      logDriver = cfg.logDriver;
    }
    // lib.optionalAttrs (cfg.storageDriver != null) {
      inherit (cfg) storageDriver;
    }
    // lib.optionalAttrs cfg.cdi {
      daemon.settings.features.cdi = true;
      rootless.daemon.settings.features.cdi = true;
    };
  };
}
