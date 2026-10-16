# SPDX-FileCopyrightText: 2026 Wael Nasreddine
# SPDX-License-Identifier: MIT
{ fleetName, hostName, ... }:
{
  users.motd = "${hostName}, a host of the ${fleetName} fleet.";
}
