# SPDX-FileCopyrightText: 2026 Wael Nasreddine
# SPDX-License-Identifier: MIT
{
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };
}
