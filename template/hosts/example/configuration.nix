# NixOS configuration for host `example`
args@{ soxincfg, ... }:

{
  imports = [
    soxincfg.nixosModules.profiles.workstation
  ];

  # This is an example host.

  soxin = {
    settings = {
      keyboard = {
        layouts = [
          { x11 = { layout = "us"; }; }
        ];
      };
    };
  };

  users.users = {
    nick = {
      isNormalUser = true;
    };
  };

  # Dummy options so the configuration builds
  fileSystems."/".label = "nixos-root";
  boot.loader.grub.device = "/dev/sda";

  home-manager.users.nick = import ./home.nix args;
}
