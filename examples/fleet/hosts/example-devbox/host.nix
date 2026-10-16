# SPDX-FileCopyrightText: 2026 Wael Nasreddine
# SPDX-License-Identifier: MIT
#
# A host file is a module, so it can take arguments such as `inputs` and `name`.
{ name, ... }:
{
  kind = "home-manager";
  system = "x86_64-linux";
  profiles = [ "workstation" ];
  modules = [ ./home.nix ];

  deploy = {
    hostname = "${name}.example.com";
    user = "alice";
  };
}
