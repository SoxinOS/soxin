{ nixpkgs, self, ... }:

let
  inherit (self.lib.modules) keyboard programmingLanguages themes tools;

  inherit (nixpkgs) lib;
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
, includeProgrammingLanguages ? false
, includeTheme ? false
, includeTools ? false
, extraOptions ? { }
}:

recursiveUpdate
{
  enable = mkEnableOption name;

  keyboardLayout = optionalAttrs includeKeyboardLayout (mkOption {
    type = keyboard.layoutModule;
    default = config.soxin.settings.keyboard.defaultLayout;
    description = "Keyboard layout to use for ${name}.";
  });

  programmingLanguages = optionalAttrs includeProgrammingLanguages (mkOption {
    type = with types; listOf (oneOf [ str programmingLanguages.programmingLanguages ]);
    default = config.soxin.settings.programmingLanguages;
    description = "Programming language to use for ${name}.";
    apply = value: map
      (v:
        if builtins.isString v then config.soxin.programmingLanguages.${v}.${name}
        else v.${name}
      )
      value;
  });

  theme = optionalAttrs includeTheme (mkOption {
    type = with types; oneOf [ str themes.themeModule ];
    default = config.soxin.settings.theme;
    description = "Theme to use for ${name}.";
    apply = value:
      if builtins.isString value then config.soxin.themes.${value}.${name}
      else value.${name};
  });

  tools = optionalAttrs includeTools (mkOption {
    type = with types; listOf (oneOf [ str tools.toolsModule ]);
    default = config.soxin.settings.tools;
    description = "Tools to use for ${name}.";
    apply = value: map
      (v:
        if builtins.isString v then config.soxin.tools.${v}.${name}
        else v.${name}
      )
      value;
  });

}
  extraOptions

