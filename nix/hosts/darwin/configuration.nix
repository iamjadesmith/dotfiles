{
  config,
  inputs,
  pkgs,
  self,
  ...
}:

let
  username = "jade";
in
{
  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [
    inputs.alacritty-theme.overlays.default
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  system.primaryUser = username;

  users.users.jade = {
    name = username;
    home = "/Users/${username}";
  };

  homebrew = {
    enable = true;
    brews = [
      "mas"
      "syncthing"
      "cmake"
      "ninja"
      "dfu-util"
      "helm"
      "gemini-cli"
      "tree-sitter-cli"
      "yt-dlp"
      "libpq"
    ];
    casks = [
      "firefox"
      "discord"
      # "nikitabobko/tap/aerospace"
      "prismlauncher"
      "nextcloud"
      "linearmouse"
      "betterdisplay"
      "google-chrome"
      "alacritty"
      "obsidian"
      "raycast"
    ];
    taps = [
      # "nikitabobko/tap"
    ];
    masApps = {
      Wireguard = 1451685025;
      Bitwarden = 1352778147;
      Tailscale = 1475387142;
    };
    onActivation.autoUpdate = true;
    onActivation.upgrade = true;
  };

  system.activationScripts.applications.text =
    let
      env = pkgs.buildEnv {
        name = "system-applications";
        paths = config.environment.systemPackages;
        pathsToLink = [ "/Applications" ];
      };
    in
    pkgs.lib.mkForce ''
      # Set up applications.
      echo "setting up /Applications..." >&2
      rm -rf /Applications/Nix\ Apps
      mkdir -p /Applications/Nix\ Apps
      find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
      while read -r src; do
        app_name=$(basename "$src")
        echo "copying $src" >&2
        ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
      done
    '';

  system.defaults = {
    NSGlobalDomain.AppleShowAllExtensions = true;
    loginwindow.GuestEnabled = false;
    finder.FXPreferredViewStyle = "clmv";
    dock.autohide = true;
    dock.autohide-delay = 0.0;
  };

  nix.settings.experimental-features = "nix-command flakes";
  nix.gc = {
    automatic = true;
    interval = {
      Weekday = 0;
      Hour = 3;
      Minute = 15;
    };
    options = "--delete-older-than 14d";
  };
  programs.zsh.enable = true;
  system.configurationRevision = self.rev or self.dirtyRev or null;
  system.stateVersion = 5;
  nixpkgs.hostPlatform = "aarch64-darwin";
}
