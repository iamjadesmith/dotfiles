{
  config,
  pkgs,
  ...
}:
{
  enable = true;
  package = pkgs.unstable.neovim;
  defaultEditor = true;
  viAlias = true;
  vimAlias = true;
}
