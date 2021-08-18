inputs@{ self, deploy-rs, lib ? nixpkgs.lib, nixpkgs, ... }:

let
  inherit (lib)
    mapAttrs
    recursiveUpdate
    ;

  # the default channel to follow.
  channelName = "nixpkgs";

  # the operating mode of Soxin
  mode = "nix-darwin";
in
mapAttrs
  (n: v: recursiveUpdate
    {
      inherit
        mode
        ;
    }
    v)
{
  ###
  # x86_64-darwin
  ###

  minimal-darwin-system =
    let
      system = "x86_64-darwin";
    in
    {
      inherit
        channelName
        system
        ;

      modules = [ ./minimal-darwin-system/configuration.nix ];
    };
}
