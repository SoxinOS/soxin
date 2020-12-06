{ lib }:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    recursiveUpdate
    ;
in
{ config
, name
, keyboardLayout ? false
, extraOptions ? { }
}:

recursiveUpdate
{
  enable = mkEnableOption name;

  keyboardLayout = mkIf keyboardLayout (mkOption {
    type = config.soxin.settings.keyboard.submodule;
    default = config.soxin.settings.keyboard.defaultLayout;
    description = "Keyboard layout to use for ${name}";
  });
}
  extraOptions
