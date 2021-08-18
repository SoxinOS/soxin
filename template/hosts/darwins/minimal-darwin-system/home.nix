{ lib, soxincfg, pkgs, ... }:

let
  inherit (lib) singleton;
in
{
  imports = [ soxincfg.nixosModules.profiles.workstation.darwin.local ];

  home.packages = with soxincfg.packages."${pkgs.system}"; singleton helloSh;

  programs.zsh.enable = true;
}
