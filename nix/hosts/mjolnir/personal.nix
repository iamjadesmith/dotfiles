{
  config,
  pkgs,
  ...
}:

let
  domain = "joejad.com";
  ssl = {
    useACMEHost = domain;
    forceSSL = true;
  };

  sources = import ./personal-sources.nix;
  system = pkgs.stdenv.hostPlatform.system;

  mkApp =
    src: extraBuildArgs:
    let
      cargoToml = builtins.fromTOML (builtins.readFile "${src}/Cargo.toml");
      packageMeta = cargoToml.package;
      package = pkgs.rustPlatform.buildRustPackage (
        {
          pname = packageMeta.name;
          version = packageMeta.version;
          inherit src;
          cargoLock.lockFile = "${src}/Cargo.lock";
          doCheck = false;

          meta.mainProgram = packageMeta.name;
        }
        // extraBuildArgs
      );
      self = {
        packages.${system}.default = package;
      };
    in
    {
      module = import "${src}/nix/module.nix" { inherit self; };
      inherit package;
    };

  apps = {
    budget = mkApp sources.budget { };
    foodLog = mkApp sources.foodLog { };
    golfRust = mkApp sources.golfRust { };
    receipt = mkApp sources.receipt {
      nativeBuildInputs = [ pkgs.pkg-config ];
      buildInputs = [ pkgs.openssl ];
    };
    running = mkApp sources.running { };
    workoutRust = mkApp sources.workoutRust { };
    stock = mkApp sources.stock { };
  };

  # Verify wedding pins over public HTTPS; the generic updater must not advance this internal fetch.
  weddingSource = builtins.fetchTree {
    type = "git";
    url = "http://joejadserver.joejad.lan:3000/jade/wedding-rsvp.git";
    rev = "5584f7538dff076aa44299e5f18161193fd1bcf5";
    narHash = "sha256-zEsbvtiIlt3vPHGfotqBqaqG8ONjUZbcRwqDmezjRYI=";
  };
  weddingCargoToml = builtins.fromTOML (builtins.readFile "${weddingSource}/Cargo.toml");
  weddingPackage = pkgs.rustPlatform.buildRustPackage {
    inherit (weddingCargoToml.package) version;
    pname = weddingCargoToml.package.name;
    src = weddingSource;
    cargoLock.lockFile = "${weddingSource}/Cargo.lock";
    doCheck = false;
    nativeBuildInputs = [
      pkgs.cmake
      pkgs.makeWrapper
      pkgs.pkg-config
    ];
    SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
    postInstall = ''
      wrapProgram "$out/bin/wedding" \
        --set-default SSL_CERT_FILE "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
    '';
    meta.mainProgram = "wedding";
  };
  weddingModule = import "${weddingSource}/nix/module.nix" {
    self.packages.${system}.default = weddingPackage;
    source = weddingSource;
  };
in
{
  imports = [
    apps.budget.module
    apps.foodLog.module
    apps.golfRust.module
    apps.receipt.module
    apps.running.module
    apps.workoutRust.module
    apps.stock.module
    weddingModule
  ];

  sops.secrets = {
    running_env = {
      owner = "workout";
      group = "workout";
      mode = "0400";
    };
    workout_env = {
      owner = "workout";
      group = "workout";
      mode = "0400";
    };
    stock_env = {
      owner = "stock";
      group = "stock";
      mode = "0400";
    };
  };

  services.budget.enable = true;

  services."food-log".enable = true;

  services."golf-rust".enable = true;

  services.receipt.enable = true;

  services.running = {
    enable = true;
    manageLocalDatabase = false;
    environmentFiles = [ config.sops.secrets.running_env.path ];
  };

  services."workout-rust" = {
    enable = true;
    environmentFiles = [ config.sops.secrets.workout_env.path ];
  };

  services.stock = {
    enable = true;
    environmentFiles = [ config.sops.secrets.stock_env.path ];
  };

  services.wedding-rsvp = {
    enable = true;
    package = weddingPackage;
    environmentFile = config.sops.templates."wedding-preview.env".path;
    databaseIdentity = "183ddd3c-3741-493b-ba69-dde20e55e1c4";
  };

  services.nginx.appendHttpConfig = ''
    limit_req_zone $binary_remote_addr zone=wedding_preview_public:10m rate=10r/s;
    limit_req_zone $binary_remote_addr zone=wedding_preview_admin:10m rate=5r/s;
  '';

  services.nginx.virtualHosts = {
    "budget.${domain}" = ssl // {
      locations."/".proxyPass = "http://127.0.0.1:8080";
    };

    "food.${domain}" = ssl // {
      locations."/".proxyPass = "http://127.0.0.1:8083";
    };

    "golf.${domain}" = ssl // {
      locations."/".proxyPass = "http://127.0.0.1:8081";
    };

    "receipt.${domain}" = ssl // {
      locations."/".proxyPass = "http://127.0.0.1:3000";
    };

    "run.${domain}" = ssl // {
      locations."/".proxyPass = "http://127.0.0.1:8085";
    };

    "workout.${domain}" = ssl // {
      locations."/".proxyPass = "http://127.0.0.1:8086";
    };

    "wedding.${domain}" = ssl // {
      forceSSL = false;
      onlySSL = true;
      extraConfig = ''
        access_log off;
        error_log /dev/null;
        limit_req_status 429;
        allow 10.3.0.0/24;
        allow 10.10.10.0/24;
        allow 10.26.27.0/24;
        allow 10.47.59.0/24;
        allow 100.64.0.0/10;
        allow fd3a:3dab:51b8::/48;
        include ${config.sops.templates."wedding-preview-network.conf".path};
        deny all;
      '';
      locations."/" = {
        proxyPass = "http://127.0.0.1:8090";
        extraConfig = ''
          limit_req zone=wedding_preview_public burst=20 nodelay;
        '';
      };
    };

    "wedding-admin.${domain}" = ssl // {
      forceSSL = false;
      onlySSL = true;
      extraConfig = ''
        access_log off;
        error_log /dev/null;
        limit_req_status 429;
        allow 10.3.0.0/24;
        allow 10.10.10.0/24;
        allow 10.26.27.0/24;
        allow 10.47.59.0/24;
        allow 100.64.0.0/10;
        allow fd3a:3dab:51b8::/48;
        include ${config.sops.templates."wedding-preview-network.conf".path};
        deny all;
      '';
      locations."/" = {
        proxyPass = "http://127.0.0.1:8091";
        extraConfig = ''
          limit_req zone=wedding_preview_admin burst=10 nodelay;
        '';
      };
    };
  };
}
