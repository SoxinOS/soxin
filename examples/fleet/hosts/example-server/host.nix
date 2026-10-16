# SPDX-FileCopyrightText: 2026 Wael Nasreddine
# SPDX-License-Identifier: MIT
{
  kind = "nixos";
  system = "x86_64-linux";
  profiles = [ "server" ];
  modules = [ ./configuration.nix ];

  deploy = {
    hostname = "example-server.example.com";
    sshUser = "alice";
  };
}
