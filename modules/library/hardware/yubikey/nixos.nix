# SPDX-FileCopyrightText: 2026 Wael Nasreddine
# SPDX-License-Identifier: MIT
{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (lib) mkIf;

  inherit (pkgs)
    yubico-piv-tool
    yubikey-manager
    yubikey-personalization
    yubikey-personalization-gui
    yubioath-desktop
    ;

  cfg = config.soxin.hardware.yubikey;
in
{
  imports = [ ./options.nix ];

  config = mkIf cfg.enable {
    environment.systemPackages = [
      yubico-piv-tool
      yubikey-manager
      yubikey-personalization
      yubikey-personalization-gui
      yubioath-desktop
    ];

    programs.gnupg.agent = mkIf cfg.gnupg-support.enable {
      enable = true;

      enableSSHSupport = cfg.gnupg-support.ssh-support.enable;
      enableExtraSocket = cfg.gnupg-support.extra-socket;
    };

    services.pcscd.enable = true;
  };
}
