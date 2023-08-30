inputs@{ self, deploy-rs, lib ? nixpkgs.lib, nixpkgs, ... }:

let
  inherit (lib)
    mapAttrs
    recursiveUpdate
    ;

  # the default channel to follow.
  channelName = "nixpkgs";

  # the operating mode of Soxin
  mode = "NixOS";
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
  # x86_64-linux
  ###

  minimal-nixos-system =
    let
      system = "x86_64-linux";
    in
    {
      # System architecture.
      inherit system;
      # <name> of the channel to be used. Defaults to `nixpkgs`
      inherit channelName;
      # Extra arguments to be passed to the modules.
      extraArgs = { };
      # Host specific configuration.
      modules = [ ./minimal-nixos-system/configuration.nix ];

      deploy = {
        hostname = "host.minimal-nixos-system.com";
        profiles.system = {
          sshUser = "root";
          user = "root";
          path = deploy-rs.lib.${system}.activate.nixos self.nixosConfigurations.minimal-nixos-system;
        };
      };
    };
}
