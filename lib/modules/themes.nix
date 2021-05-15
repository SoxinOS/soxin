{ lib, neovim }:

let
  inherit (lib)
    mkEnableOption
    mkOption
    types
  ;

in
rec {
  themeModule = types.submodule {
    options = {
      neovim = mkOption {
        type = with types; submodule {
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
      };

      rofi = mkOption {
        type = rofiModule;
        default = { };
      };
    };
  };

  rofiModule = types.submodule {
    options = {
      name = mkOption {
        type = with types; nullOr str;
        default = null;
      };
    };
  };
}
