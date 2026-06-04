{
  config,
  pkgs,
  ...
}:

let
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

  services.nginx.virtualHosts = {
    "budget.joejad.com" = {
      useACMEHost = "joejad.com";
      forceSSL = true;
      locations."/".proxyPass = "http://127.0.0.1:8080";
    };

    "food.joejad.com" = {
      useACMEHost = "joejad.com";
      forceSSL = true;
      locations."/".proxyPass = "http://127.0.0.1:8083";
    };

    "golf.joejad.com" = {
      useACMEHost = "joejad.com";
      forceSSL = true;
      locations."/".proxyPass = "http://127.0.0.1:8081";
    };

    "receipt.joejad.com" = {
      useACMEHost = "joejad.com";
      forceSSL = true;
      locations."/".proxyPass = "http://127.0.0.1:3000";
    };

    "run.joejad.com" = {
      useACMEHost = "joejad.com";
      forceSSL = true;
      locations."/".proxyPass = "http://127.0.0.1:8085";
    };

    "workout.joejad.com" = {
      useACMEHost = "joejad.com";
      forceSSL = true;
      locations."/".proxyPass = "http://127.0.0.1:8086";
    };
  };
}
