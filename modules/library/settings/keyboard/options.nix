# SPDX-FileCopyrightText: 2026 Wael Nasreddine
# SPDX-License-Identifier: MIT
#
# `soxin.settings.keyboard`: the keyboard layouts of the consoles, the X
# server and home-manager, which programs (editors, window managers) also read
# to adapt their keybindings. The first layout is the default one.
{ config, lib, ... }:

let
  inherit (lib) mkDefault mkOption types;

  cfg = config.soxin.settings.keyboard;

  layout = types.submodule (
    { config, ... }:
    {
      options = {
        x11 = {
          layout = mkOption {
            type = types.str;
            default = "us";
            example = "fr";
            description = "Keyboard layout.";
          };

          variant = mkOption {
            type = types.str;
            default = "";
            example = "colemak";
            description = "Keyboard variant.";
          };
        };

        console.keyMap = mkOption {
          type = types.str;
          example = "us";
          description = ''
            The keyboard mapping table of the virtual consoles. It defaults to
            the X11 layout, which may need changing for some variants.
          '';
        };
      };

      config.console.keyMap = mkDefault config.x11.layout;
    }
  );
in
{
  options.soxin.settings.keyboard = {
    layouts = mkOption {
      type = types.listOf layout;
      default = [ ];
      example = [
        {
          x11 = {
            layout = "us";
            variant = "colemak";
          };
          console.keyMap = "colemak";
        }
        { x11.layout = "us"; }
      ];
      description = ''
        Keyboard layouts of the consoles and the X server. The first one is the
        default. Nothing is configured while the list is empty.
      '';
    };

    defaultLayout = mkOption {
      type = layout;
      default = builtins.head cfg.layouts;
      defaultText = lib.literalExpression "builtins.head layouts";
      readOnly = true;
      description = "The default keyboard layout: the first of `layouts`.";
    };

    enableAtBoot = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to set the console's keyboard layout as early as possible, in the initrd.";
    };
  };
}
