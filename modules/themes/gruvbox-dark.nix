{ config, lib, pkgs, ... }:

with lib;

{
  config.soxin.themes.gruvbox-dark = {
    neovim = {
      plugins = singleton {
        plugin = with pkgs.vimPlugins; gruvbox-community;
        config = ''
          set background=dark
          colorscheme gruvbox
          let g:airline_theme='gruvbox'
        '';
      };
    };

    rofi = { name = "gruvbox-dark"; };
  };
}

