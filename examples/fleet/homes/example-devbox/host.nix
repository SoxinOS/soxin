# SPDX-FileCopyrightText: 2026 Wael Nasreddine
# SPDX-License-Identifier: MIT
#
# A standalone home-manager host, which Soxin builds itself as Clan has none
# (and which Clan does not deploy). `kind` defaults to "home-manager" under
# homes/. A host file is a module, so it can also take arguments such as
# `inputs` and `name`.
{
  system = "x86_64-linux";
  profiles = [ "workstation" ];
  modules = [ ./home.nix ];
}
