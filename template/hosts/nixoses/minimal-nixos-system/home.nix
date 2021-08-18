{ lib, soxincfg, pkgs, ... }:

let
  inherit (lib) singleton;
in
{
  imports = [ soxincfg.nixosModules.profiles.workstation.nixos.local ];

  home.packages = with soxincfg.packages."${pkgs.system}"; singleton helloSh;

  programs.zsh.enable = true;
}
