{ lib, soxincfg, pkgs, ... }:

let
  inherit (lib) singleton;
in
{
  imports = [ soxincfg.nixosModules.profiles.workstation ];

  home.packages = with soxincfg.packages."${pkgs.system}"; singleton helloSh;
}
