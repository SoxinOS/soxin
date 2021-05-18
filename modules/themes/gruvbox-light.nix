{ config, lib, pkgs, ... }:

with lib;
{
  config.soxin.themes.gruvbox-light = {
    neovim = {
      plugins = singleton {
        plugin = vim-color-gruvbox;
        config = ''
          set background=light
          colorscheme gruvbox
          let g:airline_theme='gruvbox'
        '';
      };
    };

    rofi = { name = "gruvbox-light"; };
  };
}
