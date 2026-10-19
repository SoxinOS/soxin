# SPDX-FileCopyrightText: 2026 Wael Nasreddine
# SPDX-License-Identifier: MIT
#
# `soxin.hardware.serial_console`: the kernel console and GRUB on the first
# serial port, at 115200 bauds.
{ lib, ... }:

{
  options.soxin.hardware.serial_console.enable = lib.mkEnableOption "the serial console";
}
