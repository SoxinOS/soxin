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
in
{
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

      tmux = {
        extraConfig = ''
          # pane number display
          set-option -g display-panes-active-colour colour250 #fg2
          set-option -g display-panes-colour colour237 #bg1

          # clock
          set-window-option -g clock-mode-colour colour109 #blue

          # bell
          set-window-option -g window-status-bell-style fg=colour235,bg=colour167 #bg, red

          ## Theme settings mixed with colors (unfortunately, but there is no cleaner way)
          set-option -g status-justify "left"
          set-option -g status-left-length "80"
          set-option -g status-right-length "80"
          set-window-option -g window-status-separator ""

          set-option -g status-left "#[fg=colour248, bg=colour241] #S #[fg=colour241, bg=colour237, nobold, noitalics, nounderscore]"
          set-option -g status-right "#[fg=colour239, bg=colour237, nobold, nounderscore, noitalics]#{prefix_highlight}#[fg=colour246,bg=colour239] %Y-%m-%d  %H:%M #[fg=colour248, bg=colour239, nobold, noitalics, nounderscore]#[fg=colour237, bg=colour248] #h "

          set-window-option -g window-status-current-format "#[fg=colour239, bg=colour248, :nobold, noitalics, nounderscore]#[fg=colour239, bg=colour214] #I #[fg=colour239, bg=colour214, bold] #W #[fg=colour214, bg=colour237, nobold, noitalics, nounderscore]"
          set-window-option -g window-status-format "#[fg=colour237,bg=colour239,noitalics]#[fg=colour223,bg=colour239] #I #[fg=colour223, bg=colour239] #W #[fg=colour239, bg=colour237, noitalics]"

          # default statusbar colors
          set-option -g status-style bg=colour237,fg=colour223,none
          set-option -g status-left-style none
          set-option -g status-right-style none

          # default window title colors
          set-window-option -g window-status-style bg=colour214,fg=colour237,none

          set-window-option -g window-status-activity-style bg=colour237,fg=colour248,none

          # active window title colors
          set-window-option -g window-status-current-style bg=default,fg=colour237

          # pane border
          set-option -g pane-active-border-style bg=colour250,fg=colour237
          set-option -g pane-border-style bg=colour237,fg=colour250

          # message infos
          set-option -g message-style bg=colour239,fg=colour223

          # writting commands inactive
          set-option -g message-command-style bg=colour239,fg=colour223
        '';
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
