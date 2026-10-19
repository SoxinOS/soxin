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

  # Soxin's users: created on the system, with groups other modules add.
  soxin.settings.users = {
    enable = true;
    userName = "alice";
    users.alice.isAdmin = true;
  };

  home-manager.users.alice = ./home.nix;

  system.stateVersion = "26.05";
}
