# SPDX-FileCopyrightText: 2026 Wael Nasreddine
# SPDX-License-Identifier: MIT
{
  users.users.alice.home = "/Users/alice";
  system.primaryUser = "alice";

  home-manager.users.alice = ./home.nix;

  system.stateVersion = 6;
}
