{config, ...}: {
  enable = true;
  enableZshIntegration = true;
  settings = builtins.fromTOML (builtins.unsafeDiscardStringContext (builtins.readFile ~/.dotfiles/.config/ohmyposh/zen.toml));
}
