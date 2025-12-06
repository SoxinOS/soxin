{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
{
  config.soxin.themes.gruvbox-dark = {
    i3 = {
      config =
        let
          # hard contrast: bg = '#282828'
          bg = "#282828";
          # soft contrast: bg = '#32302f'

          aqua = "#689d68";
          blue = "#458588";
          darkgray = "#1d2021";
          gray = "#a89984";
          green = "#98971a";
          purple = "#b16286";
          red = "#cc241d";
          white = "#ebdbb2";
          yellow = "#d79921";

        in
        {
          colors = {
            background = darkgray;

            focused = {
              border = blue;
              background = blue;
              text = darkgray;
              indicator = purple;
              childBorder = darkgray;
            };

            focusedInactive = {
              border = darkgray;
              background = darkgray;
              text = yellow;
              indicator = purple;
              childBorder = darkgray;
            };

            unfocused = {
              border = darkgray;
              background = darkgray;
              text = yellow;
              indicator = purple;
              childBorder = darkgray;
            };

            urgent = {
              border = red;
              background = red;
              text = white;
              indicator = red;
              childBorder = red;
            };
          };
        };
    };

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

    polybar = {
      extraConfig = {
        colors = {
          background = "#282828";
          background-alt = "#689d68";
          foreground = "#ebdbb2";
          foreground-alt = "#ebdbb2";
          primary = "#689d68";
          secondary = "#1d2021";
          alert = "#cc241d";
        };
      };
    };

    rofi = {
      name = "gruvbox-dark";
    };

    termite = {
      extraConfig = {
        # hard contrast: backgroundColor = "#1d2021";
        backgroundColor = "#282828";
        # soft contrast: backgroundColor = "#32302f";

        foregroundColor = "#ebdbb2";
        foregroundBoldColor = "#ebdbb2";
        colorsExtra = ''
          # dark0 + gray
          color0 = #282828
          color8 = #928374

          # neutral_red + bright_red
          color1 = #cc241d
          color9 = #fb4934

          # neutral_green + bright_green
          color2 = #98971a
          color10 = #b8bb26

          # neutral_yellow + bright_yellow
          color3 = #d79921
          color11 = #fabd2f

          # neutral_blue + bright_blue
          color4 = #458588
          color12 = #83a598

          # neutral_purple + bright_purple
          color5 = #b16286
          color13 = #d3869b

          # neutral_aqua + faded_aqua
          color6 = #689d6a
          color14 = #8ec07c

          # light4 + light1
          color7 = #a89984
          color15 = #ebdbb2
        '';
      };
    };

    tmux = {
      plugins =
        let
          tmux-gruvbox-dark-plugin-src =
            with pkgs;
            runCommandLocal "tmux-gruvbox-dark"
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
              }
              ''
                mkdir -p $out
                ln -s $theme $out/gruvbox_dark.tmux
              '';
        in
        singleton (
          pkgs.tmuxPlugins.mkTmuxPlugin {
            pluginName = "gruvbox-dark";
            inherit (pkgs.vimPlugins.gruvbox-community) version;
            src = tmux-gruvbox-dark-plugin-src;
          }
        );
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
