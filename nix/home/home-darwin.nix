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
      extraConfigFiles = {
        aerospace = ".config/aerospace";
      };
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

  launchd.agents.theme-mode-sync = {
    enable = true;
    config = {
      ProgramArguments = [
        "${dotfilesDirectory}/scripts/theme-mode"
        "sync-macos"
      ];
      RunAtLoad = true;
      StartInterval = 300;
      StandardOutPath = "/tmp/theme-mode-sync.out.log";
      StandardErrorPath = "/tmp/theme-mode-sync.err.log";
    };
  };
}
