{
  personalInputs,
  config,
  ...
}:

{
  imports = [
    personalInputs.budget.nixosModules.default
    personalInputs.foodLog.nixosModules.default
    personalInputs.golfRust.nixosModules.default
    personalInputs.receipt.nixosModules.default
    personalInputs.running.nixosModules.default
    personalInputs.workoutRust.nixosModules.default
  ];

  sops.secrets = {
    running_env = {
      owner = "running";
      group = "running";
      mode = "0400";
    };
    workout_env = {
      owner = "workout";
      group = "workout";
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
