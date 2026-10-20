{ meta, pkgs }:
{
  enable = true;
  # On Darwin the app comes from the Homebrew cask; Home Manager only writes the config.
  package = if pkgs.stdenv.hostPlatform.isDarwin then null else pkgs.ghostty;

  settings = {
    # Follows the system light/dark appearance. Ghostty also reports theme changes to
    # programs (DEC mode 2031), which Neovim uses to switch colorschemes live.
    theme = "light:Catppuccin Latte,dark:TokyoNight Night";

    font-family = "JetBrainsMono Nerd Font";
    font-size =
      if meta.name == "joejadmbp" then
        18
      else if meta.name == "mini" then
        21
      else
        14;

    window-padding-x = 4;
    window-padding-y = 8;
    maximize = true;

    cursor-style = "block";
    cursor-style-blink = false;
    mouse-hide-while-typing = true;
    macos-option-as-alt = true;

    # no-cursor keeps the block cursor at the prompt. ssh-terminfo installs
    # Ghostty's terminfo on hosts that do not already have it.
    shell-integration-features = "no-cursor,ssh-terminfo";
  };
}
