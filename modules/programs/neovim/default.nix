{
  mode,
  config,
  pkgs,
  lib,
  soxin,
  ...
}:

with lib;
let
  inherit (soxin.lib.modules) neovim;

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
            set nobackup
          '';
          description = ''
            Custom vimrc lines.
          '';
        };

        extraLuaConfig = mkOption {
          type = types.lines;
          default = "";
          example = ''
            vim.opt.nobackup = true
          '';
          description = ''
            Custom lua lines.
          '';
        };

        mapleader = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = ''
            Set the mapleader early in int the init.
          '';
        };

        plugins = mkOption {
          type = neovim.pluginWithConfigModule;
          default = [ ];
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
    # add all plugins installed by themes
    { soxin.programs.neovim.plugins = cfg.theme.plugins; }

    (optionalAttrs (mode == "NixOS") {
      # TODO: Add support for NeoVim on NixOS.
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
      # TODO: I wish home-manager had a defaultEditor as well!
      home.sessionVariables = {
        EDITOR = "nvim";
      };

      programs.neovim =
        {
          enable = true;
          inherit (cfg) extraLuaConfig plugins;

          extraConfig =
            ""
            + (optionalString (cfg.mapleader != null) ''let mapleader = "${cfg.mapleader}"'')
            + cfg.extraConfig;

          # Add the Python's neovim plugin
          extraPython3Packages = ps: with ps; [ pynvim ];
        }
        # Create aliases
        // (genAttrs [
          "viAlias"
          "vimAlias"
          "vimdiffAlias"
        ] (name: true))
        # Add support for NodeJS, Python 2 and 3 as well as Ruby
        // (genAttrs [
          "withNodeJs"
          "withPython3"
          "withRuby"
        ] (name: true));
    })
  ]);
}
