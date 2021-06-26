{ nixpkgs, self, ... }:

let
  inherit (self.lib.modules) keyboard themes;

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
, includeTheme ? false
, includeTool ? false
, includeProgrammingLanguages ? false
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

  theme = optionalAttrs includeTheme (mkOption {
    type = with types; oneOf [ str themes.themeModule ];
    default = config.soxin.settings.theme;
    description = "Theme to use for ${name}.";
    apply = value:
      if builtins.isString value then config.soxin.themes.${value}.${name}
      else value.${name};
  });

  tool = optionalAttrs includeTool (mkOption {
    type = with types; listOf [ str modules.tools.toolsModule ];
    default = config.soxin.settings.tools;
    description = "Tool to use for ${name}.";
    apply = value: map (v:
      if builtins.isString v then config.soxin.tools.${v}.${name}
      else v.${name}
    ) value;
  });

  
  programmingLanguages = optionalAttrs includeProgrammingLanguages (mkOption {
    type = with types; listOf [ str modules.programmingLanguages.programmingLanguagesModule ];
    default = config.soxin.settings.programmingLanguages;
    description = "Programming language to use for ${name}.";
    apply = value: map (v:
      if builtins.isString v then config.soxin.programmingLanguages.${v}.${name}
      else v.${name}
    ) value;
  });
}
  extraOptions

