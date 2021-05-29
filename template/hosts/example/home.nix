{ pkgs, soxincfg, ... }:

{
  imports = [
    soxincfg.nixosModules.profiles.workstation
  ];

  home.packages = with pkgs; [ helloSh ];
}
