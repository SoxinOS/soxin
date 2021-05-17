{ mode, config, pkgs, lib, soxin, ... }:

with lib;
let
  cfg = config.soxin.programs.neovim;
in
{
  options = {
    soxin.programs.neovim = soxin.lib.mkSoxinModule {
      inherit config;
      name = "neovim";
      includeKeyboardLayout = true;
      includeTheme = true;
      extraOptions = {
        extraConfig = mkOption {
          type = types.lines;
          default = "";
          example = ''
            set nocompatible
            set nobackup
          '';
          description = ''
            Custom vimrc lines.
          '';
        };

        plugins = mkOption {
          type = with types; listOf (either package soxin.lib.modules.neovim.pluginWithConfigModule);
          default = cfg.theme.plugins;
          defaultText = "The plugins added by the theme";
          example = literalExample ''
            with pkgs.vimPlugins; [
              yankring
              vim-nix
              { plugin = vim-startify;
                config = "let g:startify_change_to_vcs_root = 0";
              }
            ]
          '';
          description = ''
            List of vim plugins to install optionally associated with
            configuration to be placed in init.vim.
          '';
        };
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    (optionalAttrs (mode == "NixOS") {
      # TODO!
      # programs.neovim = {
      #   enable = true;
      #
      #   # make it a default editor
      #   defaultEditor = true;
      #
      #   # Create a symlink of nvim to vi and vim
      #   viAlias = true;
      #   vimAlias = true;
      #
      #   # Add support for NodeJS, Python 2 and 3 as well as Ruby
      #   # withNodeJs = true;
      #   # withPython3 = true;
      #   withRuby = true;
      #
      #   # Add the Python's neovim plugin
      #   # extraPython3Packages = ps: with ps; [ pynvim ];
      #
      #   configure = {
      #     customRC = extraRC;
      #     packages.myVimPackage = { inherit start opt; };
      #   };
      # };
    })

    (optionalAttrs (mode == "home-manager") {
      home.sessionVariables = { EDITOR = "nvim"; };

      programs.neovim = {
        inherit (cfg) enable extraConfig;

        plugins = cfg.plugins ++ cfg.theme.plugins;

        # Create aliases
        viAlias = true;
        vimAlias = true;
        vimdiffAlias = true;

        # Add support for NodeJS, Python 2 and 3 as well as Ruby
        withNodeJs = true;
        withPython3 = true;
        withRuby = true;

        # Add the Python's neovim plugin
        extraPython3Packages = ps: with ps; [ pynvim ];
      };
    })
  ]);
}
