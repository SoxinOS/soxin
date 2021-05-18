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

    zsh = {
      plugins = singleton {
        src = pkgs.vimPlugins.gruvbox-community;
        name = "gruvbox-dark";
        file = "share/vim-plugins/gruvbox-community/gruvbox_256palette.sh";
      };
    };

    rofi = { name = "gruvbox-dark"; };
  };
}
