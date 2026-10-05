{
  config,
  pkgs,
  lib,
  meta ? null,
  user,
  homeDirectory,
  extraConfigFiles ? { },
  enableAlacritty ? false,
  enableAlacrittyTheme ? false,
  enableNeovim ? true,
  ...
}:
let
  inherit (config.lib.file) mkOutOfStoreSymlink;
  dotfilesDirectory = "${homeDirectory}/.dotfiles";
  configFiles = {
    nvim = ".config/nvim";
    "opencode/opencode.json" = ".config/opencode/opencode.json";
    "starship.toml" = ".config/starship.toml";
  }
  // lib.optionalAttrs enableAlacrittyTheme {
    "alacritty/themes/tokyonight.toml" = ".config/alacritty/tokyonight-night.toml";
    "alacritty/themes/catppuccin-frappe.toml" = ".config/alacritty/catppuccin-frappe.toml";
    "alacritty/themes/catppuccin-latte.toml" = ".config/alacritty/catppuccin-latte.toml";
  }
  // extraConfigFiles;
  # Share OpenCode skills with Claude Code and Codex. Link each skill individually
  # so both discovery directories can also hold independently installed skills.
  sharedSkills = lib.attrNames (
    lib.filterAttrs (_name: type: type == "directory") (builtins.readDir ../../.config/opencode/skills)
  );
in
{
  home.username = user;
  home.homeDirectory = homeDirectory;
  xdg.enable = true;

  xdg.configFile = lib.mapAttrs (_name: source: {
    source = mkOutOfStoreSymlink "${dotfilesDirectory}/${source}";
  }) configFiles;

  home.stateVersion = "24.05";

  home.packages = [ ];

  home.file = lib.listToAttrs (
    lib.concatMap
      (
        directory:
        map (name: {
          name = "${directory}/${name}";
          value.source = mkOutOfStoreSymlink "${dotfilesDirectory}/.config/opencode/skills/${name}";
        }) sharedSkills
      )
      [
        ".claude/skills"
        ".agents/skills"
      ]
  );

  home.activation.initTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    ''
      if [ ! -e "$HOME/.config/theme-mode" ]; then
        printf '%s\n' dark > "$HOME/.config/theme-mode"
      fi
    ''
    + lib.optionalString enableAlacrittyTheme ''
      if [ ! -e "$HOME/.config/alacritty/theme.toml" ]; then
        mkdir -p "$HOME/.config/alacritty"
        cp "${dotfilesDirectory}/.config/alacritty/tokyonight-night.toml" "$HOME/.config/alacritty/theme.toml"
      fi
    ''
  );

  home.sessionVariables = { };

  programs = {
    home-manager.enable = true;
    zsh = import ./zsh.nix { inherit config; };
    fzf = import ./fzf.nix { inherit pkgs; };
    tmux = import ./tmux.nix { inherit pkgs; };
    git = import ./git.nix { inherit config pkgs; };
    zoxide = import ./zoxide.nix { inherit pkgs; };
    starship.enable = true;
    yazi = import ./yazi.nix;
  }
  // lib.optionalAttrs enableAlacritty {
    alacritty = import ./alacritty.nix {
      inherit
        pkgs
        lib
        meta
        ;
    };
  }
  // lib.optionalAttrs enableNeovim {
    neovim = import ./neovim.nix { inherit config pkgs; };
  };
}
