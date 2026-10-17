# SPDX-FileCopyrightText: 2026 Wael Nasreddine
# SPDX-License-Identifier: MIT
{
  # Where `clan machines update` deploys the machine.
  clan.core.networking.targetHost = "root@example-server.example.com";

  boot.loader.grub.devices = [ "/dev/sda" ];

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  users.users.alice = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };

  home-manager.users.alice = ./home.nix;

  system.stateVersion = "26.05";
}
