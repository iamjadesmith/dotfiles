{
  lib,
  meta,
  pkgs,
  ...
}:

let
  binary = "/home/jade/.opencode/bin/opencode";
  updateTools = [
    pkgs.bash
    pkgs.coreutils
    pkgs.curl
    pkgs.gnugrep
    pkgs.gnused
    pkgs.gnutar
    pkgs.gzip
    pkgs.jq
    pkgs.util-linux
  ];
in
{
  # The upstream V2 binary is dynamically linked and needs the NixOS loader.
  programs.nix-ld.enable = true;

  systemd.services.opencode-update = {
    description = "Install the latest stable OpenCode V2 release";
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    path = updateTools;
    serviceConfig.Type = "oneshot";
    script = ''
      installed_version() {
        local output
        output="$(${binary} --version)"
        output="''${output##* }"
        printf '%s\n' "''${output#v}"
      }

      old_version=""
      if [[ -x ${binary} ]]; then
        old_version="$(installed_version)"
      fi

      latest_version="$(curl -fsSL https://opencode.ai/update/api/latest/cli/npm | jq -er '.version')" || {
        # Keep a working installation when the update endpoint is unavailable.
        [[ -n "$old_version" ]]
        exit $?
      }

      if [[ "$old_version" == "$latest_version" ]]; then
        exit 0
      fi

      runuser -u jade -- env HOME=/home/jade VERSION="$latest_version" bash -c \
        'set -euo pipefail; curl -fsSL https://opencode.ai/v2/install | bash -s -- --no-modify-path'

      [[ "$(installed_version)" == "$latest_version" ]]
      ${lib.optionalString (meta.hostname == "mjolnir") ''
        if [[ -n "$old_version" ]]; then
          # The web unit starts after this one; queue the restart without waiting for ourselves.
          systemctl --no-block try-restart opencode-web.service
        fi
      ''}
    '';
  };

  systemd.timers.opencode-update = {
    description = "Check for stable OpenCode V2 updates daily";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5min";
      OnUnitActiveSec = "1d";
      Persistent = true;
    };
  };
}
