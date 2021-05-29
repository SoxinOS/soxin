# NixOS configuration for host `example`
{ soxincfg, lib, ... }:

let
  inherit (lib) singleton;
in
{
  imports = [ soxincfg.nixosModules.profiles.workstation ];

  # Dummy options so the configuration builds
  fileSystems."/".label = "nixos-root";
  boot.loader.grub.device = "/dev/sda";

  home-manager.users.nick = { ... }: {
    imports = singleton ./home.nix;
  };
}
