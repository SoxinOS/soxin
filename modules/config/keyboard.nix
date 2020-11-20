{ mode, config, lib, ... }:

with lib;
let
  cfg = config.soxin.settings.keyboard;

  layoutModule = types.submodule ({ config, ... }: {
    options = {
      x11 = {
        layout = mkOption {
          type = types.str;
          default = "us";
          example = "fr";
          description = "Keyboard layout";
        };

        variant = mkOption {
          type = types.str;
          default = "";
          example = "colemak";
          description = "Keyboard variant";
        };
      };

      console = {
        keyMap = mkOption {
          type = types.str;
          example = "us";
          description = ''
            The keyboard mapping table for the virtual consoles. The default is
            the layout associated with the keyMap but you may need to change this
            depending on your keyboard variant.
          '';
        };
      };
    };

    config = {
      console.keyMap = mkDefault config.x11.layout;
    };
  });
in
{
  options = {
    soxin.settings.keyboard = {
      layouts = mkOption {
        default = [ ];
        type = with types; listOf layoutModule;
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
        type = layoutModule;
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
