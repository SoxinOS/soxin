{ soxincfg, lib, ... }:

let
  inherit (lib) singleton;
in
{
  imports = [
    # hardware configuration for this host
    ./hardware-configuration.nix

    # import the workstation profile that configures a workstation.
    soxincfg.nixosModules.profiles.workstation.nixos.local
  ];

  # the user nick is created by the core profiles which is automatically added
  # to the configuration of all supported systems.
  home-manager.users.nick = { ... }: {
    imports = singleton ./home.nix;
  };
}
