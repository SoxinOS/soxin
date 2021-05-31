{ pkgs, lib, mode, ... }:

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
              { x11 = { layout = "us"; variant = "intl"; }; }
            ];
          };
        };
      };
    }

    # enable the sandbox on NixOS
    (optionalAttrs (mode == "NixOS") {
      nix.useSandbox = true;

      # configure the users
      users.users = {
        nick = {
          isNormalUser = true;
          shell = pkgs.zsh;
        };
      };
    })
  ];
}
