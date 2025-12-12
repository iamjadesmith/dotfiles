{
  config,
  pkgs,
  ...
}: {
  enable = true;
  lfs.enable = true;
  settings = {
    user.name = "Jade Smith";
    user.email = "jade@jade-smith.com";
    pull.rebase = true;
    init.defaultBranch = "main";
  };
}
