{
  lib,
  meta ? { },
  pkgs,
  ...
}:

let
  isServer = meta.server or false;

  commonPackages = with pkgs; [
    R
    age
    basedpyright
    fd
    fluxcd
    git
    kubectl
    lazygit
    lemminx
    lua5_1
    lua-language-server
    neovim
    nil
    nixfmt
    nodejs
    opencode
    ripgrep
    ruff
    rustup
    sops
    starship
    stylua
    tmux
    tree
    vscode-json-languageserver
    yaml-language-server
    zoxide
  ];

  linuxPackages = with pkgs; [
    bash
    cargo
    fzf
    gcc
    gnumake
    helm
    jq
    luajitPackages.luarocks-nix
    postgresql_18
    stow
    tree-sitter
    unzip
    wget
    zsh
  ];

  linuxServerPackages = with pkgs; [
    cifs-utils
    nfs-utils
    samba
  ];

  darwinPackages = with pkgs; [
    ansible
    black
    ffmpeg-headless
    luajitPackages.luarocks
    mkalias
    poppler-utils
    rbw
    ruby
    rust-analyzer
    speedtest-cli
    yubikey-manager
  ];
in
{
  nixpkgs.config.permittedInsecurePackages = [
    "electron-39.8.10"
  ];

  environment.systemPackages =
    commonPackages
    ++ lib.optionals pkgs.stdenv.isLinux linuxPackages
    ++ lib.optionals (pkgs.stdenv.isLinux && isServer) linuxServerPackages
    ++ lib.optionals pkgs.stdenv.isDarwin darwinPackages;
}
