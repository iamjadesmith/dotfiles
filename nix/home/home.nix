{
  config,
  pkgs,
  lib,
  meta ? null,
  user,
  homeDirectory,
  extraConfigFiles ? { },
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

  home.sessionVariables = { };

  programs = {
    home-manager.enable = true;
    zsh = import ./zsh.nix { inherit config; };
    fzf = import ./fzf.nix { inherit pkgs; };
    tmux = import ./tmux.nix { inherit pkgs; };
    git = import ./git.nix { inherit config pkgs; };
    delta = import ./delta.nix;
    zoxide = import ./zoxide.nix { inherit pkgs; };
    starship.enable = true;
    yazi = import ./yazi.nix;
  }
  // lib.optionalAttrs enableNeovim {
    neovim = import ./neovim.nix { inherit config pkgs; };
  };
}
