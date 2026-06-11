{
  lib,
  meta,
  pkgs,
  ...
}:

{
  nixpkgs.config.permittedInsecurePackages = [
    "electron-39.8.10"
  ];

  environment.systemPackages =
    with pkgs;
    [
      R
      age
      basedpyright
      bash
      cargo
      fd
      fluxcd
      fzf
      gcc
      git
      gnumake
      helm
      jq
      kubectl
      lazygit
      lemminx
      lua
      lua-language-server
      luajitPackages.luarocks-nix
      neovim
      nil
      nixfmt
      nodejs
      opencode
      postgresql_18
      ripgrep
      ruff
      rustup
      sops
      starship
      stow
      stylua
      tmux
      tree
      tree-sitter
      unzip
      vscode-json-languageserver
      wget
      yaml-language-server
      zoxide
      zsh
    ]
    ++ lib.optionals meta.server [
      cifs-utils
      nfs-utils
      samba
    ];
}
