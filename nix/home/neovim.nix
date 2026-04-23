{
  config,
  pkgs,
  ...
}:
{
  enable = true;
  defaultEditor = true;
  sideloadInitLua = true;
  viAlias = true;
  vimAlias = true;
  withRuby = false;
  withPython3 = false;
}
