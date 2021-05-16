{ lib, neovim }:
let
  inherit (lib)
    mkEnableOption
    mkOption
    types
    ;

in
rec {
  themeModule = with types; submodule {
    options = {
      i3 = mkOption {
        type = i3Module;
        default = { };
      };

      neovim = mkOption {
        type = neovimModule;
        default = { };
      };

      rofi = mkOption {
        type = rofiModule;
        default = { };
      };

      tmux = mkOption {
        type = tmuxModule;
        default = { };
      };
    };
  };

  i3Module = with types; submodule {
    options = {
      config = mkOption {
        type = nullOr str;
        default = null;
      };
    };
  };

  tmuxModule = with types; submodule {
    options = {
      extraConfig = mkOption {
        type = nullOr str;
        default = null;
      };
    };
  };

  neovimModule = with types; submodule {
    options = {
      plugins = mkOption {
        type = listOf (either package neovim.pluginWithConfigModule);
        default = [ ];
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
          </para><para>
          This option is mutually exclusive with <varname>configure</varname>.
        '';
      };
    };
  };

  rofiModule = with types; submodule {
    options = {
      name = mkOption {
        type = nullOr str;
        default = null;
      };
    };
  };
}
