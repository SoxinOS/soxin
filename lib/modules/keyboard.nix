{ nixpkgs, ... }:

let
  inherit (nixpkgs) lib;
  inherit (lib)
    mkDefault
    mkOption
    types
    ;
in
{
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
}
