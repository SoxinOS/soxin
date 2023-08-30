{ config, lib, soxincfg, ... }:

let
  inherit (lib) singleton;
in
{
  imports = [
    # import the workstation profile that configures a workstation.
    soxincfg.nixosModules.profiles.workstation.darwin.local
  ];

  # the user nick is created by the core profiles which is automatically added
  # to the configuration of all supported systems.
  home-manager.users.nick = { ... }: {
    imports = singleton ./home.nix;
  };
}
