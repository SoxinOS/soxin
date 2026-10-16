# SPDX-FileCopyrightText: 2026 Wael Nasreddine
# SPDX-License-Identifier: MIT
{
  kind = "darwin";
  system = "aarch64-darwin";
  profiles = [ "workstation" ];
  modules = [ ./configuration.nix ];
}
