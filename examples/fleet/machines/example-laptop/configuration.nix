# SPDX-FileCopyrightText: 2026 Wael Nasreddine
# SPDX-License-Identifier: MIT
{
  clan.core.networking.targetHost = "alice@example-laptop.example.com";

  soxin.settings.users = {
    enable = true;
    userName = "alice";
    users.alice.sshKeys = [ ];
  };
  system.primaryUser = "alice";

  home-manager.users.alice = ./home.nix;

  system.stateVersion = 6;
}
