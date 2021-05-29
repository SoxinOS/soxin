channels@{ ... }:

let
  inherit (channels.nixpkgs) callPackage;
in
{
  rbrowser = callPackage ./rbrowser { };
  rofi-i3-support = callPackage ./rofi-i3-support { };
}
