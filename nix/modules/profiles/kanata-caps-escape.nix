{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    kanata
  ];

  services.kanata = {
    enable = true;
    keyboards.internalKeyboard.config = ''
      (defsrc
       caps
      )
      (defalias
       caps esc
      )

      (deflayer base
       @caps
      )
    '';
  };
}
