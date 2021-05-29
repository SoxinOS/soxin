{ pkgs, lib, mode, ... }:

let
  inherit (lib) mkMerge optionalAttrs;
in
{
  config = mkMerge [
    # configure the theme
    { soxin.settings.theme = "gruvbox-dark"; }

    # enable the sandbox on NixOS
    (optionalAttrs (mode == "NixOS") { nix.useSandbox = true; })
  ];
}
