{
  config,
  pkgs,
  ...
}:
{
  enable = true;
  lfs.enable = true;
  settings = {
    user.name = "Jade Smith";
    user.email = "jade@jade-smith.com";
    pull.rebase = true;
    init.defaultBranch = "main";
    diff.tool = "nvim";
    difftool.nvim.cmd = "nvim -d \"$LOCAL\" \"$REMOTE\"";
  };
  signing.format = "openpgp";
}
