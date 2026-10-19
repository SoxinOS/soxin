# SPDX-FileCopyrightText: 2026 Wael Nasreddine
# SPDX-License-Identifier: MIT
{ config, lib, ... }:

{
  imports = [ ./options.nix ];

  config = lib.mkIf config.soxin.hardware.serial_console.enable {
    boot.kernelParams = [ "console=tty0 console=ttyS0,115200n8" ];
    boot.loader.grub.extraConfig = ''
      serial --speed=115200 --unit=0 --word=8 --parity=no --stop=1
      terminal_input serial console
      terminal_output serial console
    '';
  };
}
