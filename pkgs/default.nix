{ callPackage, ... }:

{
  rbrowser = callPackage ./rbrowser { };
  rofi-i3-support = callPackage ./rofi-i3-support { };
}
