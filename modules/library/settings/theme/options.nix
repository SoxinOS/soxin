# SPDX-FileCopyrightText: 2026 Wael Nasreddine
# SPDX-License-Identifier: MIT
#
# `soxin.settings.theme`: one theme, chosen by name from `soxin.themes`, that
# programs read their colours and plugins from (for instance
# `config.soxin.settings.theme.tmux.plugins`). A theme sets what it has for
# each program; gruvbox-dark and gruvbox-light come as examples.
{ config, lib, ... }:

let
  inherit (lib)
    attrNames
    literalExpression
    mkDefault
    mkOption
    types
    ;

  # A tmux plugin with configuration placed after it.
  tmuxPlugin = types.submodule {
    options = {
      plugin = mkOption {
        type = types.package;
        description = "The plugin.";
      };

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        description = "Configuration placed after the plugin.";
      };
    };
  };

  # A zsh plugin, sourced from `src`.
  zshPlugin = types.submodule (
    { config, ... }:
    {
      options = {
        src = mkOption {
          type = types.path;
          description = "Path to the plugin folder, added to fpath and PATH.";
        };

        name = mkOption {
          type = types.str;
          description = "The name of the plugin.";
        };

        file = mkOption {
          type = types.str;
          description = "The plugin script to source.";
        };
      };

      config.file = mkDefault "${config.name}.plugin.zsh";
    }
  );

  attrsOption = mkOption {
    type = types.attrs;
    default = { };
  };

  theme = types.submodule {
    # Settings for programs not listed below.
    freeformType = types.attrsOf types.raw;

    options = {
      i3.config = attrsOption;
      polybar.extraConfig = attrsOption;
      termite.extraConfig = attrsOption;

      rofi.name = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "The name of the rofi theme.";
      };

      neovim.plugins = mkOption {
        # home-manager's programs.neovim.plugins type checks the plugins
        # where they are used.
        type = types.listOf types.raw;
        default = [ ];
        example = literalExpression "[ pkgs.vimPlugins.gruvbox-community ]";
        description = "Neovim plugins of the theme, as home-manager's programs.neovim.plugins takes them.";
      };

      tmux.plugins = mkOption {
        type = types.listOf (types.either types.package tmuxPlugin);
        default = [ ];
        description = "tmux plugins of the theme.";
      };

      zsh.plugins = mkOption {
        type = types.listOf zshPlugin;
        default = [ ];
        description = "zsh plugins of the theme.";
      };
    };
  };
in
{
  imports = [
    ./gruvbox-dark.nix
    ./gruvbox-light.nix
  ];

  options.soxin = {
    themes = mkOption {
      type = types.attrsOf theme;
      default = { };
      description = "The themes a configuration can choose from.";
    };

    settings.theme = mkOption {
      type = types.nullOr (types.enum (attrNames config.soxin.themes));
      default = null;
      example = "gruvbox-dark";
      apply = name: if name == null then null else config.soxin.themes.${name};
      description = "The theme programs use, by name; reading it gives the theme itself.";
    };
  };
}
