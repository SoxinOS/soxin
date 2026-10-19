# SPDX-FileCopyrightText: 2026 Wael Nasreddine
# SPDX-License-Identifier: MIT
#
# `soxin.hardware.yubikey`: YubiKey tools, pcscd and GnuPG's agent (with SSH
# support) on NixOS and home-manager. `gnupg-support.ssh-support.public-certificate-pem`
# is the public half of the SSH key, for the fleet's SSH client configuration.
{ lib, pkgs, ... }:

let
  inherit (lib) mkEnableOption mkOption types;
in
{
  options.soxin.hardware.yubikey = {
    enable = mkEnableOption "Whether to enable Yubikey.";

    gnupg-support = {
      enable = mkEnableOption "Whether to enable GnuPG support with the YubiKey.";

      extra-socket = mkEnableOption "Whether to enable an extra socket for the GPG agent. This is useful for enabling GPG forwarding to remote servers.";

      default-key = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          The default GnuPG key of the YubiKey.
        '';
      };

      default-cache-ttl = mkOption {
        type = types.nullOr types.int;
        default = 7200;
        description = ''
          Set the time a cache entry is valid to the given number of
          seconds. The default is 2 hours (7200 seconds).
        '';
      };

      max-cache-ttl = mkOption {
        type = types.nullOr types.int;
        default = 7200;
        description = ''
          Set the maximum time a cache entry is valid to n seconds. After this
          time a cache entry will be expired even if it has been accessed
          recently or has been set using gpg-preset-passphrase. The default is
          2 hours (7200 seconds).
        '';
      };

      # TODO: Does Yubikey support SSH outside of GnuPG? Right now, it's
      # tightly coupled with GnuPG support.
      ssh-support = {
        enable = mkEnableOption "Whether to enable SSH support with YubiKey.";

        default-cache-ttl = mkOption {
          type = types.nullOr types.int;
          default = 7200;
          description = ''
            Set the time a cache entry used for SSH keys is valid to the
            given number of seconds. The default is 2 hours (7200 seconds).
          '';
        };

        max-cache-ttl = mkOption {
          type = types.nullOr types.int;
          default = 7200;
          description = ''
            Set the maximum time a cache entry used for SSH keys is valid to n
            seconds. After this time a cache entry will be expired even if it has
            been accessed recently or has been set using gpg-preset-passphrase.
            The default is 2 hours (7200 seconds).
          '';
        };

        public-certificate-pem = mkOption {
          apply = value: if builtins.isPath value then value else pkgs.writeText "id_rsa.pub" value;
          type = types.nullOr (
            types.oneOf [
              types.lines
              types.path
            ]
          );
          default = null;
          description = ''
            The public certificate of the SSH key.
          '';
        };
      };
    };
  };
}
