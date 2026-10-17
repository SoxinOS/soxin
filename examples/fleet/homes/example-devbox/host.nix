# SPDX-FileCopyrightText: 2026 Wael Nasreddine
# SPDX-License-Identifier: MIT
#
# A standalone home-manager host, which Soxin builds itself as Clan has none.
# A host file is a module, so it can take arguments such as `inputs` and
# `name`. `kind` defaults to "home-manager" under homes/.
{ name, ... }:
{
  system = "x86_64-linux";
  profiles = [ "workstation" ];
  modules = [ ./home.nix ];

  deploy = {
    hostname = "${name}.example.com";
    user = "alice";
  };
}
