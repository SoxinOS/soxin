{ lib, modules }:
let
  inherit (lib)
    optionalAttrs
    mkEnableOption
    mkOption
    recursiveUpdate
    types
    ;
in
{ config
, name
, includeKeyboardLayout ? false
, includeTheme ? false
, extraOptions ? { }
}:

recursiveUpdate
{
  enable = mkEnableOption name;

  keyboardLayout = optionalAttrs includeKeyboardLayout (mkOption {
    type = modules.keyboard.layoutModule;
    default = config.soxin.settings.keyboard.defaultLayout;
    description = "Keyboard layout to use for ${name}.";
  });

  theme = optionalAttrs includeTheme (mkOption {
    type = with types; oneOf [ str modules.themes.themeModule ];
    default = config.soxin.settings.theme;
    description = "Theme to use for ${name}.";
    apply = value:
      if builtins.isString value then config.soxin.themes.${value}.${name}
      else value.${name};
  });
}
  extraOptions
