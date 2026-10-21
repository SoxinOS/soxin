# SPDX-FileCopyrightText: 2026 Wael Nasreddine
# SPDX-License-Identifier: MIT
{
  lib,
  pkgs,
  ...
}:

with lib;

{
  config.soxin.themes.gruvbox-light = {
    neovim = {
      plugins = singleton {
        plugin = with pkgs.vimPlugins; gruvbox-community;
        config = ''
          set background=light
          colorscheme gruvbox
          let g:airline_theme='gruvbox'
        '';
      };
    };

    rofi = {
      name = "gruvbox-light";
    };
  };
}
