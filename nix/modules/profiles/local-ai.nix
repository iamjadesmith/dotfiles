{ ... }:

{
  systemd.tmpfiles.rules = [
    "d /var/lib/podman 0755 root root - -"
    "d /var/lib/podman/ollama 0755 root root - -"
    "d /var/lib/podman/open-webui 0755 root root - -"
  ];

  virtualisation.docker = {
    enable = true;
    logDriver = "json-file";
    daemon.settings.features.cdi = true;
    rootless.daemon.settings.features.cdi = true;
  };

  virtualisation.oci-containers.containers = {
    ollama = {
      image = "ollama/ollama";
      ports = [ "11434:11434" ];
      volumes = [
        "/var/lib/podman/ollama:/root/.ollama"
      ];
      autoStart = true;
      extraOptions = [
        "--device=nvidia.com/gpu=all"
      ];
    };

    open-webui = {
      image = "ghcr.io/open-webui/open-webui:main";
      ports = [ "3000:8080" ];
      volumes = [
        "/var/lib/podman/open-webui:/app/backend/data"
      ];
      autoStart = true;
    };
  };
}
