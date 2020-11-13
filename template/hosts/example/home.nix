# home-manager configuration for user `nick`
{ soxincfg }:
{ pkgs, ... }:

{
  imports = [
    soxincfg.nixosModules.profiles.workstation
  ];

  soxin = {
    settings = {
      keyboard = {
        layouts = [
          { x11 = { layout = "us"; variant = "intl"; }; }
        ];
      };
    };
  };

  home.packages = with pkgs; [
    helloSh
  ];
}
