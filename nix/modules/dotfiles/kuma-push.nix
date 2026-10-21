{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.dotfiles.kumaPush;
  urlDir = "/var/lib/kuma-push";
  dumps = config.services.postgresqlBackup;
  dumpSuffix =
    {
      none = "";
      gzip = ".gz";
      zstd = ".zstd";
    }
    .${dumps.compression};

  # Push URLs carry the monitor's token, so they stay out of the repo: each host
  # keeps /var/lib/kuma-push/<name> holding the Uptime Kuma push URL. A missing
  # file skips the push, so the host still builds and runs before it is set up.
  pushScript =
    name:
    pkgs.writeShellScript "kuma-push-${name}" ''
      url_file=${urlDir}/${name}
      if [[ ! -r "$url_file" ]]; then
        echo "no Uptime Kuma push URL in $url_file; skipping" >&2
        exit 0
      fi
      ${pkgs.curl}/bin/curl --fail --silent --show-error --output /dev/null \
        --max-time 10 --retry 3 --retry-all-errors \
        --get --data-urlencode "status=''${1:-up}" --data-urlencode "msg=''${2:-OK}" \
        "$(< "$url_file")"
    '';

  dumpCheckName = "postgres-dump-check";
  dumpCheck = pkgs.writeShellScript dumpCheckName ''
    stale=()
    for db in ${lib.escapeShellArgs dumps.databases}; do
      dump="${dumps.location}/$db.sql${dumpSuffix}"
      if [[ -z "$(${pkgs.findutils}/bin/find "$dump" -mmin -${toString (26 * 60)} 2>/dev/null)" ]]; then
        stale+=("$db")
      fi
    done

    if (( ''${#stale[@]} > 0 )); then
      echo "stale or missing dumps: ''${stale[*]}" >&2
      ${pushScript dumpCheckName} down "stale or missing dumps: ''${stale[*]}"
      exit 1
    fi
    ${pushScript dumpCheckName} up "all ${toString (builtins.length dumps.databases)} dumps under 26h old"
  '';
in
{
  options.dotfiles.kumaPush = {
    units = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "borgbackup-job-mjolnir" ];
      description = ''
        Services that push to an Uptime Kuma push monitor after each successful
        run, using the URL in /var/lib/kuma-push/<service name>.
      '';
    };

    postgresDumps.enable = lib.mkEnableOption ''
      a daily check that every services.postgresqlBackup dump is under 26 hours
      old, pushed to the Uptime Kuma URL in /var/lib/kuma-push/${dumpCheckName}
    '';
  };

  config = lib.mkMerge [
    {
      systemd.tmpfiles.rules = lib.mkIf (cfg.units != [ ] || cfg.postgresDumps.enable) [
        "d ${urlDir} 0700 root root - -"
      ];

      # ExecStartPost only runs when the service succeeded. "-" keeps a failed
      # push from marking the job failed; "+" runs it as root outside the unit's
      # sandbox, so jobs with their own user can still read the root-only URL.
      systemd.services = lib.genAttrs cfg.units (name: {
        serviceConfig.ExecStartPost = lib.mkAfter [ "-+${pushScript name}" ];
      });
    }

    (lib.mkIf cfg.postgresDumps.enable {
      systemd.services.${dumpCheckName} = {
        description = "Check PostgreSQL dumps are fresh and report to Uptime Kuma";
        serviceConfig.Type = "oneshot";
        script = "exec ${dumpCheck}";
      };

      # Dumps run at 01:15 by default.
      systemd.timers.${dumpCheckName} = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "*-*-* 02:30:00";
          Persistent = true;
        };
      };
    })
  ];
}
