{
  config,
  homeDirectory,
  lib,
  meta,
  pkgs,
  user,
  ...
}:

let
  dotfilesDirectory = "${homeDirectory}/.dotfiles";
  themeMode = "dark"; # Set to "auto" to follow the macOS appearance.
in
{
  imports = [
    (import ./home.nix {
      inherit
        config
        pkgs
        lib
        meta
        user
        homeDirectory
        ;
      enableAlacritty = true;
      enableAlacrittyTheme = true;
      enableNeovim = false;
    })
  ];

  programs.zsh.initContent = lib.mkBefore ''
    # Cache brew shellenv so Homebrew tools are available without slowing every shell startup.
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
      BREW_CACHE="$HOME/.cache/brew-shellenv.zsh"
      if [[ ! -f "$BREW_CACHE" ]] || [[ "/opt/homebrew/bin/brew" -nt "$BREW_CACHE" ]]; then
        /opt/homebrew/bin/brew shellenv > "$BREW_CACHE"
      fi
      source "$BREW_CACHE"

      LIBPQ_BIN="$HOMEBREW_PREFIX/opt/libpq/bin"
      if [[ -d "$LIBPQ_BIN" ]] && [[ ":$PATH:" != *":$LIBPQ_BIN:"* ]]; then
        export PATH="$LIBPQ_BIN:$PATH"
      fi
    fi

    if [[ -d "$HOME/Library/Python" ]]; then
      export PATH="$PATH:$HOME/Library/Python/3.9/bin"
    fi
  '';

  home.file.".hammerspoon/init.lua" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDirectory}/.hammerspoon/init.lua";
    force = true;
  };

  launchd.agents.theme-mode-sync = {
    enable = true;
    config = {
      ProgramArguments = [
        "${dotfilesDirectory}/scripts/theme-mode"
        (if themeMode == "auto" then "sync-macos" else themeMode)
      ];
      RunAtLoad = true;
      StartInterval = 300;
      StandardOutPath = "/tmp/theme-mode-sync.out.log";
      StandardErrorPath = "/tmp/theme-mode-sync.err.log";
    };
  };

  launchd.agents.opencode-upgrade = {
    enable = true;
    config = {
      ProgramArguments = [
        "/opt/homebrew/bin/brew"
        "upgrade"
        "anomalyco/tap/opencode-v2"
      ];
      RunAtLoad = true;
      StartInterval = 86400;
    };
  };
}
