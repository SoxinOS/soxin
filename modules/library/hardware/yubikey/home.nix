# SPDX-FileCopyrightText: 2026 Wael Nasreddine
# SPDX-License-Identifier: MIT
{
  config,
  lib,
  ...
}:

let
  inherit (lib) mkIf;

  cfg = config.soxin.hardware.yubikey;
in
{
  imports = [ ./options.nix ];

  config = mkIf cfg.enable {
    services.gpg-agent = mkIf cfg.gnupg-support.enable {
      enable = true;

      enableSshSupport = cfg.gnupg-support.ssh-support.enable;
      enableExtraSocket = cfg.gnupg-support.extra-socket;

      defaultCacheTtl = cfg.gnupg-support.default-cache-ttl;
      maxCacheTtl = cfg.gnupg-support.max-cache-ttl;

      defaultCacheTtlSsh = cfg.gnupg-support.ssh-support.default-cache-ttl;
      maxCacheTtlSsh = cfg.gnupg-support.ssh-support.max-cache-ttl;
    };
  };
}
