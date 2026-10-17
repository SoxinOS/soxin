# SPDX-FileCopyrightText: 2026 Wael Nasreddine
# SPDX-License-Identifier: MIT
#
# Soxin's settings of a Clan machine. Clan imports configuration.nix from this
# directory by itself, so it is not listed in `modules`.
{
  kind = "nixos";
  system = "x86_64-linux";
  profiles = [ "server" ];
}
