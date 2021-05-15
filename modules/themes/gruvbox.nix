{ config, lib, pkgs, ... }:

with lib;

let
  vim-color-gruvbox = with pkgs; vimUtils.buildVimPluginFrom2Nix rec {
    pname = "gruvbox";
    version = "3.0.1-rc.0";

    src = fetchFromGitHub {
      owner = "morhetz";
      repo = "gruvbox";
      rev = "v${version}";
      sha256 = "01as1pkrlbzhcn1kyscy476w8im3g3wmphpcm4lrx7nwdq8ch7h1";
    };

    dependencies = [ ];
  };
in {
  config.soxin.themes = {
    gruvbox-dark = {
      neovim = {
        plugins = singleton {
          plugin = vim-color-gruvbox;
          config = ''
            set background=dark
            colorscheme gruvbox
            let g:airline_theme='gruvbox'
          '';
        };
      };

      rofi = { name = "gruvbox-dark"; };
    };

    gruvbox-light = {
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
  };
}
