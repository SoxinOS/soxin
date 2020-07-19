{ config, pkgs, lib, ... }:

{
  imports = [
    (import ./.. { inherit lib; }).nixos
  ];

  networking.hostName = "soxin-example";

  environment.etc."home.nix".source = ./home.nix;

  soxin.hardware.bluetooth.enable = true;

  environment.systemPackages = with pkgs; [
    vim home-manager
  ];

  users.users = {
    root.password = "root";
    soxin.password = "soxin";
  };
  users.mutableUsers = false;

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "20.03"; # Did you read the comment?
}
