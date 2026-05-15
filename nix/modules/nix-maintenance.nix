{ ... }:

{
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
    randomizedDelaySec = "1h";
  };

  nix.optimise = {
    automatic = true;
    dates = [ "weekly" ];
  };
}
