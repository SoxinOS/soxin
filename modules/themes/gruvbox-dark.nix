{ config, lib, ... }:

with lib;

{
  config.soxin.themes.gruvbox = {
    rofi = {
      theme = "gruvbox-dark";
    };
  };
}
