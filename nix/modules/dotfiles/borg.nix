{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.dotfiles.borg;
  borgHome = "/var/lib/borg";
  borgSshKey = "${borgHome}/.ssh/id_ed25519";
  borgKnownHosts = "${borgHome}/.ssh/known_hosts";
  borgRsh = "ssh -i ${borgSshKey} -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile=${borgKnownHosts}";

  mkJob =
    _name: job:
    {
      inherit (job)
        paths
        repo
        compression
        startAt
        ;
      encryption = {
        mode = "repokey-blake2";
        passCommand = "cat ${config.sops.secrets.borgbackup_passphrase.path}";
      };
      prune.keep.weekly = job.keepWeekly;
      environment = {
        BORG_RSH = borgRsh;
      }
      // job.environment;
    }
    // lib.optionalAttrs (job.preHook != null) { inherit (job) preHook; }
    // lib.optionalAttrs (job.postHook != null) { inherit (job) postHook; };
in
{
  options.dotfiles.borg = {
    enable = lib.mkEnableOption "shared Borg backup defaults";

    authorizedKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "SSH authorized keys for the borg user.";
    };

    jobs = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            paths = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              description = "Paths included in the backup.";
            };

            repo = lib.mkOption {
              type = lib.types.str;
              description = "Borg repository target.";
            };

            compression = lib.mkOption {
              type = lib.types.str;
              default = "zstd,6";
              description = "Borg compression setting.";
            };

            startAt = lib.mkOption {
              type = lib.types.str;
              default = "weekly";
              description = "systemd calendar expression for the backup.";
            };

            keepWeekly = lib.mkOption {
              type = lib.types.int;
              default = 7;
              description = "Number of weekly backups to keep.";
            };

            preHook = lib.mkOption {
              type = lib.types.nullOr lib.types.lines;
              default = null;
              description = "Optional pre-backup hook.";
            };

            postHook = lib.mkOption {
              type = lib.types.nullOr lib.types.lines;
              default = null;
              description = "Optional post-backup hook.";
            };

            environment = lib.mkOption {
              type = lib.types.attrsOf lib.types.str;
              default = { };
              description = "Additional environment for the Borg job.";
            };
          };
        }
      );
      default = { };
      description = "Borg backup jobs keyed by job name.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.borgbackup ];

    sops.secrets.borgbackup_passphrase = { };

    users.groups.borg = { };
    users.users.borg = {
      isSystemUser = true;
      group = "borg";
      home = borgHome;
      createHome = true;
      shell = pkgs.bash;
      openssh.authorizedKeys.keys = cfg.authorizedKeys;
    };

    systemd.tmpfiles.rules = [
      "d ${borgHome}/.ssh 0700 borg borg - -"
    ];

    systemd.services.borg-ssh-keygen = {
      description = "Generate borg SSH key if missing";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        User = "borg";
        Group = "borg";
      };
      script = ''
        if [ ! -f ${borgSshKey} ]; then
          install -d -m 700 -o borg -g borg ${borgHome}/.ssh
          ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -N "" -f ${borgSshKey}
        fi
      '';
    };

    services.borgbackup.jobs = lib.mapAttrs mkJob cfg.jobs;
  };
}
