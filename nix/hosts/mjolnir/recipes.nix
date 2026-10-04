{
  config,
  pkgs,
  ...
}:

# Keep ~/recipes (read by meal-planner) in sync with Forgejo: a push webhook
# hits hooks.joejad.com, and the unprivileged webhook user may start only
# recipes-pull.service, which fast-forwards the checkout as jade.
let
  recipeDir = "/home/jade/recipes";
  pullUnit = "recipes-pull.service";
  startPull = pkgs.writeShellScript "start-recipes-pull" ''
    exec ${pkgs.systemd}/bin/systemctl start --no-block ${pullUnit}
  '';
in
{
  sops.secrets.recipes_webhook_secret = { };

  sops.templates."recipes-webhook.env" = {
    content = ''
      RECIPES_WEBHOOK_SECRET=${config.sops.placeholder.recipes_webhook_secret}
    '';
    owner = "webhook";
    group = "webhook";
    mode = "0400";
    restartUnits = [ "webhook.service" ];
  };

  services.webhook = {
    enable = true;
    ip = "127.0.0.1";
    port = 9000;
    enableTemplates = true;
    hooksTemplated.recipes-pull = builtins.toJSON {
      id = "recipes-pull";
      execute-command = "${startPull}";
      http-methods = [ "POST" ];
      response-message = "pull queued";
      trigger-rule.and = [
        {
          match = {
            type = "payload-hmac-sha256";
            secret = "{{ getenv `RECIPES_WEBHOOK_SECRET` }}";
            parameter = {
              source = "header";
              name = "X-Forgejo-Signature";
            };
          };
        }
        {
          match = {
            type = "value";
            value = "refs/heads/main";
            parameter = {
              source = "payload";
              name = "ref";
            };
          };
        }
      ];
    };
  };

  systemd.services.webhook.serviceConfig.EnvironmentFile =
    config.sops.templates."recipes-webhook.env".path;

  security.polkit.extraConfig = ''
    polkit.addRule(function (action, subject) {
      if (action.id == "org.freedesktop.systemd1.manage-units" &&
          action.lookup("unit") == "${pullUnit}" &&
          action.lookup("verb") == "start" &&
          subject.user == "webhook") {
        return polkit.Result.YES;
      }
    });
  '';

  # Also runs at boot to catch pushes made while mjolnir was down.
  systemd.services.recipes-pull = {
    description = "Fast-forward ${recipeDir} from Forgejo";
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.git ];
    # origin fetches over anonymous HTTP; pushes still use SSH.
    script = "git -C ${recipeDir} pull --ff-only";
    serviceConfig = {
      Type = "oneshot";
      User = "jade";
      Group = "users";
    };
  };
}
