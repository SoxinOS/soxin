{
  pkgs,
  lib,
  mode,
  ...
}:

let
  inherit (lib) mkMerge optionalAttrs;
in
{
  config = mkMerge [
    # configure the theme
    { soxin.settings.theme = "gruvbox-dark"; }

    # configure the keyboard
    {
      soxin = {
        settings = {
          keyboard = {
            layouts = [
              {
                x11 = {
                  layout = "us";
                };
              }
            ];
          };
        };
      };
    }

    # enable the sandbox on NixOS
    (optionalAttrs (mode == "NixOS") {
      nix.useSandbox = true;

      # configure the users
      users.mutableUsers = false; # do not allow runtime mods to the users
      users.users = {
        nick = {
          extraGroups = [ "wheel" ];
          isNormalUser = true;
          password = "nick";
          shell = pkgs.zsh;
        };

        root = {
          password = "toor";
        };
      };
    })
  ];
}
