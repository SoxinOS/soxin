{ config, lib, ... }:

with lib;

{
  config.soxin.themes.gruvbox-dark = {
    rofi = {
      name = "gruvbox-dark";
    };
  };
}
