{ mode, soxin, config, lib, ... }:

with lib;
let
  cfg = config.soxin.settings.keyboard;
in
{
  options = {
    soxin.settings.keyboard = {
      layouts = mkOption {
        default = [ ];
        type = with types; listOf soxin.lib.modules.keyboard.layoutModule;
        description = ''
          Keyboard layouts to use for consoles and Xorg server. The first
          layout of this list will be used as the default layout.
          The supported layouts are in the example associated with this option.
        '';
        example = [
          {
            x11 = { layout = "us"; variant = "colemak"; };
            console = { keyMap = "colemak"; };
          }
          {
            x11 = { layout = "fr"; variant = "bepo"; };
            console = { keyMap = "fr-bepo"; };
          }
          {
            x11 = { layout = "us"; };
          }
        ];
      };

      defaultLayout = mkOption {
        type = soxin.lib.modules.keyboard.layoutModule;
        default = builtins.head cfg.layouts;
        internal = true;
        description = ''
          Default keyboard layout. Defaults to the first layout set in
          soxin.settings.keyboard.layouts.
        '';
      };

      enableAtBoot = recursiveUpdate
        (mkEnableOption ''
          Enable setting keyboard layout as early as possible (in initrd).
        '')
        { default = true; };
    };
  };

  config = mkMerge [
    {
      assertions = [
        {
          assertion = cfg.layouts != [ ];
          message = "soxin.keyboard.layouts cannot be empty";
        }
      ];
    }

    (optionalAttrs (mode == "NixOS") {
      console = {
        inherit (cfg.defaultLayout.console) keyMap;
        earlySetup = cfg.enableAtBoot;
      };

      services.xserver = {
        layout = concatMapStringsSep "," (l: l.x11.layout) cfg.layouts;
        xkbVariant = concatMapStringsSep "," (l: l.x11.variant) cfg.layouts;
      };
    })

    (optionalAttrs (mode == "home-manager") {
      home.keyboard = {
        layout = concatMapStringsSep "," (l: l.x11.layout) cfg.layouts;
        variant = concatMapStringsSep "," (l: l.x11.variant) cfg.layouts;
      };
    })
  ];
}
