{
  config,
  lib,
  inputs,
  outputs,
  pkgs,
  meta,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  nix = {
    package = pkgs.nixVersions.stable;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  nixpkgs = {
    overlays = [
      outputs.overlays.additions
      outputs.overlays.unstable
      inputs.alacritty-theme.overlays.default
    ];
    config = {
      permittedInsecurePackages = [ "electron-25.9.0" ];
      allowUnfree = true;
    };
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  services.qemuGuest.enable = lib.mkDefault true;

  fileSystems."/" = lib.mkDefault {
    device = "/dev/disk/by-label/nixos";
    autoResize = true;
    fsType = "ext4";
  };

  networking.hostName = meta.hostname;
  networking.networkmanager.enable = true;

  time.timeZone = "America/Chicago";

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  systemd.tmpfiles.rules = [
    "L+ /usr/local/bin - - - - /run/current-system/sw/bin/"
  ];
  virtualisation.docker.logDriver = "json-file";

  services.k3s = {
    enable = true;
    role = "server";
    tokenFile = /var/lib/rancher/k3s/server/token;
    extraFlags = toString (
      [
        "--write-kubeconfig-mode \"0644\""
        "--cluster-init"
        "--disable servicelb"
        "--disable traefik"
        "--disable local-storage"
      ]
      ++ (
        if meta.hostname == "agent-1" then
          [ ]
        else
          [
            "--server https://agent-1:6443"
          ]
      )
    );
    clusterInit = (meta.hostname == "agent-1");
  };

  services.openiscsi = {
    enable = true;
    name = "iqn.2016-04.com.open-iscsi:${meta.hostname}";
  };

  users.users.joejad = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [ "wheel" ];
    packages = with pkgs; [
      tree
    ];
    hashedPassword = "$y$j9T$zCosUIu8eNq21sMsgQ7ya.$0oQ.aynDLokO77HvIjV.EEMDrnI25n8VQJgEd3RlSx8";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDzIbh1w5EeOjFTWaQ9V5PFHf5ipVNQ33sjzpsNDNgfD jade@Jades-MacBook-Pro.local"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFmO691Ujio3I1tNUGEnSnyhjl0vLCBNi3Q/u0P+UvEX joejad@joejadserver"
    ];
  };

  programs.zsh.enable = true;

  environment.systemPackages = with pkgs; [
    R
    bash
    cifs-utils
    fluxcd
    fzf
    gcc
    git
    gnumake
    helm
    intel-gpu-tools
    k3s
    kubectl
    lazygit
    lua
    lua-language-server
    luajitPackages.luarocks-nix
    nfs-utils
    nil
    nixfmt
    oh-my-posh
    postgresql_17
    ripgrep
    samba
    stow
    stylua
    tmux
    unstable.cargo
    unstable.neovim
    zoxide
    zsh
  ];

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  networking.firewall.enable = false;
  system.stateVersion = "23.11";
}
