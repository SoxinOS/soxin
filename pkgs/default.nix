{
  callPackage,
  lib,
  system,
  ...
}:

let
  inherit (lib) findSingle filterAttrs;

  pkgs = {
    rbrowser = callPackage ./rbrowser { };
    rofi-i3-support = callPackage ./rofi-i3-support { };
  };

  hasElement = list: elem: (findSingle (x: x == elem) "none" "multiple" list) != "none";
in
filterAttrs (name: pkg: hasElement pkg.meta.platforms system) pkgs
