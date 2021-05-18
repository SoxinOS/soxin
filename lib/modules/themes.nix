{ lib, neovim, zsh }:
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

      termite = mkOption {
        type = termiteModule;
        default = { };
      };

      tmux = mkOption {
        type = tmuxModule;
        default = { };
      };

      zsh = mkOption {
        type = zshModule;
        default = { };
      };
    };
  };

 # TODO: Make this more specific by getting home-manager's type
  termiteModule = with types; submodule {
    options = {
      extraConfig = mkOption {
        type = attrs;
        default = { };
      };
    };
  };

  tmuxModule = with types; submodule {
    options = {
      plugins = mkOption {
        type = with types; listOf (either package soxin.lib.modules.tmux.pluginWithConfigModule);
        default = [ ];
        example = literalExample ''
          with pkgs; [
            tmuxPlugins.cpu
            {
              plugin = tmuxPlugins.resurrect;
              extraConfig = "set -g @resurrect-strategy-nvim 'session'";
            }
            {
              plugin = tmuxPlugins.continuum;
              extraConfig = '''
                set -g @continuum-restore 'on'
                set -g @continuum-save-interval '60' # minutes
              ''';
            }
          ]
        '';
        description = ''
          List of tmux plugins to be included at the end of your tmux
          configuration. The sensible plugin, however, is defaulted to
          run at the top of your configuration.
        '';
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

  zshModule = with types; submodule {
    options = {
      # TODO: Get this directly from home-manager instead of copying it
      plugins = mkOption {
        type = types.listOf zsh.pluginModule;
        default = [ ];
        example = literalExample ''
          [
            {
              # will source zsh-autosuggestions.plugin.zsh
              name = "zsh-autosuggestions";
              src = pkgs.fetchFromGitHub {
                owner = "zsh-users";
                repo = "zsh-autosuggestions";
                rev = "v0.4.0";
                sha256 = "0z6i9wjjklb4lvr7zjhbphibsyx51psv50gm07mbb0kj9058j6kc";
              };
            }
            {
              name = "enhancd";
              file = "init.sh";
              src = pkgs.fetchFromGitHub {
                owner = "b4b4r07";
                repo = "enhancd";
                rev = "v2.2.1";
                sha256 = "0iqa9j09fwm6nj5rpip87x3hnvbbz9w9ajgm6wkrd5fls8fn8i5g";
              };
            }
          ]
        '';
        description = "Plugins to source in <filename>.zshrc</filename>.";
      };
    };
  };
}
