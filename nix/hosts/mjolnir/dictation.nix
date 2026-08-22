{
  config,
  lib,
  pkgs,
  ...
}:

let
  domain = "joejad.com";
  stateDir = "/var/lib/speaches";
  apiEnvironmentFile = "${stateDir}/api.env";
  speachesPort = 8002;
  model = "deepdml/faster-whisper-large-v3-turbo-ct2";
  containerService = config.virtualisation.oci-containers.containers.speaches.serviceName;
  createApiKey = pkgs.writeShellScript "speaches-create-api-key" ''
    if [[ ! -s "${apiEnvironmentFile}" ]]; then
      umask 077
      printf 'API_KEY=%s\n' "$(${pkgs.openssl}/bin/openssl rand -hex 32)" > "${apiEnvironmentFile}"
    fi
  '';
in
{
  hardware.nvidia-container-toolkit.enable = true;

  systemd.tmpfiles.rules = [
    "d ${stateDir} 0700 root root - -"
  ];

  virtualisation.oci-containers.containers.speaches = {
    image = "ghcr.io/speaches-ai/speaches:0.9.0-rc.3-cuda-12.6.3@sha256:5c6206a349e90b9a6782342917e72f84fc7cb60e8afd540f6aa625831ac1fd0f";
    pull = "missing";
    autoStart = true;
    ports = [ "127.0.0.1:${toString speachesPort}:8000" ];
    environment = {
      ENABLE_UI = "false";
      LOG_LEVEL = "info";
      PRELOAD_MODELS = builtins.toJSON [ model ];
      STT_MODEL_TTL = "-1";
      WHISPER__COMPUTE_TYPE = "float16";
      WHISPER__INFERENCE_DEVICE = "cuda";
    };
    environmentFiles = [ apiEnvironmentFile ];
    volumes = [
      "speaches-hf-cache:/home/ubuntu/.cache/huggingface/hub"
    ];
    capabilities.ALL = false;
    extraOptions = [
      "--device=nvidia.com/gpu=all"
      "--security-opt=no-new-privileges"
    ];
  };

  systemd.services.${containerService} = {
    requires = [ "nvidia-container-toolkit-cdi-generator.service" ];
    after = [ "nvidia-container-toolkit-cdi-generator.service" ];
    preStart = lib.mkBefore ''
      ${createApiKey}
    '';
    serviceConfig.RestartSec = "10s";
  };

  services.nginx.virtualHosts."dictation.${domain}" = {
    useACMEHost = domain;
    forceSSL = true;
    extraConfig = ''
      client_max_body_size 32M;
    '';
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString speachesPort}";
      extraConfig = ''
        proxy_read_timeout 300s;
        proxy_send_timeout 300s;
      '';
    };
  };
}
