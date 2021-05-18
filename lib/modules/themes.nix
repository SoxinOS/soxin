{ lib, neovim }:
let
  inherit (lib)
    mkOption
    types
    ;
in
rec {
  themeModule = with types; submodule {
    options = {
      neovim = mkOption {
        type = neovimModule;
        default = { };
      };

      rofi = mkOption {
        type = rofiModule;
        default = { };
      };
    };
  };


  neovimModule = with types; submodule {
    options = {
      # TODO: Get this directly from home-manager instead of copying it
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
