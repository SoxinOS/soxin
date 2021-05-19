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

    rofi = { name = "gruvbox-dark"; };

    tmux = {
      plugins =
        let
          tmux-gruvbox-dark-plugin-src = with pkgs;
            runCommandNoCCLocal "tmux-gruvbox-dark"
              {
                theme = writeShellScript "tmux-gruvbox-dark.tmux" ''
                  set -e

                  # pane number display
                  tmux set-option -g display-panes-active-colour colour250 #fg2
                  tmux set-option -g display-panes-colour colour237 #bg1

                  # clock
                  tmux set-window-option -g clock-mode-colour colour109 #blue

                  # bell
                  tmux set-window-option -g window-status-bell-style fg=colour235,bg=colour167 #bg, red

                  ## Theme settings mixed with colors (unfortunately, but there is no cleaner way)
                  tmux set-option -g status-justify "left"
                  tmux set-option -g status-left-length "80"
                  tmux set-option -g status-right-length "80"
                  tmux set-window-option -g window-status-separator ""

                  tmux set-option -g status-left "#[fg=colour248, bg=colour241] #S #[fg=colour241, bg=colour237, nobold, noitalics, nounderscore]"
                  tmux set-option -g status-right "#[fg=colour239, bg=colour237, nobold, nounderscore, noitalics]#{prefix_highlight}#[fg=colour246,bg=colour239] %Y-%m-%d  %H:%M #[fg=colour248, bg=colour239, nobold, noitalics, nounderscore]#[fg=colour237, bg=colour248] #h "

                  tmux set-window-option -g window-status-current-format "#[fg=colour239, bg=colour248, :nobold, noitalics, nounderscore]#[fg=colour239, bg=colour214] #I #[fg=colour239, bg=colour214, bold] #W #[fg=colour214, bg=colour237, nobold, noitalics, nounderscore]"
                  tmux set-window-option -g window-status-format "#[fg=colour237,bg=colour239,noitalics]#[fg=colour223,bg=colour239] #I #[fg=colour223, bg=colour239] #W #[fg=colour239, bg=colour237, noitalics]"

                  # default statusbar colors
                  tmux set-option -g status-style bg=colour237,fg=colour223,none
                  tmux set-option -g status-left-style none
                  tmux set-option -g status-right-style none

                  # default window title colors
                  tmux set-window-option -g window-status-style bg=colour214,fg=colour237,none

                  tmux set-window-option -g window-status-activity-style bg=colour237,fg=colour248,none

                  # active window title colors
                  tmux set-window-option -g window-status-current-style bg=default,fg=colour237

                  # pane border
                  tmux set-option -g pane-active-border-style bg=colour250,fg=colour237
                  tmux set-option -g pane-border-style bg=colour237,fg=colour250

                  # message infos
                  tmux set-option -g message-style bg=colour239,fg=colour223

                  # writting commands inactive
                  tmux set-option -g message-command-style bg=colour239,fg=colour223
                '';
              } ''
              mkdir -p $out
              ln -s $theme $out/gruvbox_dark.tmux
            '';
        in
        singleton (pkgs.tmuxPlugins.mkTmuxPlugin {
          pluginName = "gruvbox-dark";
          inherit (pkgs.vimPlugins.gruvbox-community) version;
          src = tmux-gruvbox-dark-plugin-src;
        });
    };

    zsh = {
      plugins = singleton {
        src = pkgs.vimPlugins.gruvbox-community;
        name = "gruvbox-dark";
        file = "share/vim-plugins/gruvbox-community/gruvbox_256palette.sh";
      };
    };
  };
}
